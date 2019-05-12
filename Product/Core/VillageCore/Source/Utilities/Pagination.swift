//
//  Pagination.swift
//  VillageCore
//
//  Created by Rob Feldmann on 5/11/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import Promises
import SwiftyJSON

struct PaginatedCounts {
    let totalCount: Int
    let totalPages: Int
    let currentPage: Int
    let perPage: Int
}

internal extension PaginatedCounts {
    
    init(from response: JSON) {
        self = PaginatedCounts(
            totalCount: response["totalCount"].intValue,
            totalPages: response["totalPages"].intValue,
            currentPage: response["currPage"].intValue,
            perPage: response["perPage"].intValue
        )
    }
}

/// Represents a page of results from the server
struct PaginatedResults<T> {
    
    /// The values for the current page
    let values: [T]
    
    /// The updated page count information
    let counts: PaginatedCounts
}

public protocol PaginationDelegate: class {
    
    /// A new page of data was retreived from the server.
    ///
    /// - Parameter newIndexPathsToReload: The new indexPaths, if any, that
    ///               need to be updated. If it's the first page of results
    ///               this parameter will be `nil`.
    func onFetchCompleted(with newIndexPathsToReload: [IndexPath]?)
    
    /// An error occurred when trying to fetch a page of data.
    ///
    /// - Parameter error: The error returned from the server.
    func onFetchFailed(with error: Error)
    
}

/// A type that knows how to handle and fetch paged data from the network.
public protocol PaginatedType: class {
    associatedtype T
    
    /// Whether the first page of results have been fetched or not.
    var needsFetching: Bool { get }
    
    /// The total number of values on the server that can be fetched.
    var totalCount: Int { get }

    /// The number of values that have already been fetched from the server.
    var currentCount: Int { get }

    /// A delegate that is responsible for doing something with the newly fetched
    /// paged data, or any errors that might be encountered
    var delegate: PaginationDelegate? { get set }
    
    /// Obtain the value at the specified IndexPath.
    ///
    /// - Parameter index: The item or row index
    /// - Returns: The value if it has been fetched, or `nil`.
    func value(at index: Int) -> T?

    /// Determine whether the value at the given indexPath has been fetched.
    ///
    /// - Parameter indexPath: The indexPath to check
    /// - Returns: `true` if the item has not been fetched yet, otherwise `false`
    func isLoadingValue(at indexPath: IndexPath) -> Bool
    
    /// Determine which of the visible indexPaths need to be reloaded.
    ///
    /// Example use:
    ///
    /// ```
    /// func onFetchCompleted(with newIndexPathsToReload: [IndexPath]?) {
    ///     let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows ?? []
    ///     let indexPathsToReload = groups.visibleIndexPathsToReload(
    ///         indexPathsForVisibleRows,
    ///         intersecting: newIndexPathsToReload ?? []
    ///     )
    ///     tableView.reloadRows(at: indexPathsToReload, with: .automatic)
    /// }
    /// ```
    /// - Parameters:
    ///   - indexPathsForVisibleRows: The indexPaths that are currently visible
    ///       from `.indexPathsForVisibleRows` or `.indexPathsForVisibleItems`
    ///       UIKit methods.
    ///   - indexPaths: The indexPaths that contain new or updated data, which
    ///       comes from the `onFetchCompleted(with:)` method of `PaginationDelegate`
    /// - Returns: The indexPaths that should be reloaded, if any
    func visibleIndexPathsToReload(_ indexPathsForVisibleRows: [IndexPath], intersecting indexPaths: [IndexPath]) -> [IndexPath]
    
    /// Informs the `PaginatedType` to fetch a new set of values; either the
    /// first page, or the next page. It is safe to call this method repeatedly
    /// in quick succession.
    func fetchValues()
    
}

/// A concrete type that exposes the `PaginatedType` API and implements
/// fetching paged data as necessary.
public class Paginated<T>: PaginatedType {
    
    /// A closure that can fetch an arry of type `T` for the given page
    typealias FetchValuesClosure = (_ page: Int) -> Promise<PaginatedResults<T>>
    
    public weak var delegate: PaginationDelegate?
    
    private var values: [T] = []
    
    private var paginatedCounts: PaginatedCounts = PaginatedCounts(totalCount: 0, totalPages: 0, currentPage: 0, perPage: 0)

    private var isFetchInProgress = false
    
    private var performFetch: FetchValuesClosure
    
    /// A `Pagination` must be initialized with a closure that knows how to fetch
    /// a page of data.
    ///
    /// - Parameter fetchValues: A closure that can fetch an arry data
    ///                          for the given page
    required init(fetchValues: @escaping FetchValuesClosure) {
        self.performFetch = fetchValues
    }
    
    public var totalCount: Int {
        return paginatedCounts.totalCount
    }
    
    public var currentCount: Int {
        return values.count
    }
    
    public var needsFetching: Bool = true
    
    public func value(at index: Int) -> T? {
        if index < values.count {
            return values[index]
        } else {
            return nil
        }
    }
    
    public func isLoadingValue(at indexPath: IndexPath) -> Bool {
        return indexPath.row >= values.count
    }
    
    public func visibleIndexPathsToReload(_ indexPathsForVisibleRows: [IndexPath], intersecting indexPaths: [IndexPath]) -> [IndexPath] {
        let indexPathsIntersection = Set(indexPathsForVisibleRows).intersection(indexPaths)
        return Array(indexPathsIntersection)
    }
    
    public func fetchValues() {
        guard !isFetchInProgress else {
            return
        }
        
        let nextPage = paginatedCounts.currentPage + 1
        
        if !needsFetching {
            guard paginatedCounts.totalPages > 0 && nextPage <= paginatedCounts.totalPages else {
                return
            }
        }
        
        isFetchInProgress = true
        
        firstly {
            performFetch(nextPage)
        }.then { [weak self] result in
            guard let `self` = self else { return }
            
            self.paginatedCounts = result.counts
            self.values.append(contentsOf: result.values)
            let indexPathsToReload: [IndexPath]?
            if result.counts.currentPage > 1 {
                indexPathsToReload = self.calculateIndexPathsToReload(from: result.values)
            } else {
                indexPathsToReload = nil
            }
            self.delegate?.onFetchCompleted(with: indexPathsToReload)
        }.catch { [weak self] error in
            self?.delegate?.onFetchFailed(with: error)
        }.always { [weak self] in
            self?.isFetchInProgress = false
            self?.needsFetching = false
        }
    }
    
    /// Calculates the index paths for the last page of values received from
    /// the server so that the delegate can refresh only the content that has
    /// changed, instead of reloading the whole table or collection view.
    ///
    /// - Parameter newValues: The latest page of fetched values
    /// - Returns: The indexPaths that need to be reloaded
    private func calculateIndexPathsToReload(from newValues: [T]) -> [IndexPath] {
        let startIndex = values.count - newValues.count
        let endIndex = startIndex + newValues.count
        return (startIndex..<endIndex).map { IndexPath(row: $0, section: 0) }
    }
    
}
