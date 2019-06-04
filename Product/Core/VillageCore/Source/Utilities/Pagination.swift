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
import Differ

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
    
    /// The tableView section for the paginated data. Default == 0.
    func tableViewSection() -> Int
    
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

public extension PaginationDelegate {
    
    func tableViewSection() -> Int {
        return 0
    }
    
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
    func fetchValues(at indexPaths: [IndexPath])
    
}

/// A concrete type that exposes the `PaginatedType` API and implements
/// fetching paged data as necessary.
public class Paginated<T>: PaginatedType {
    
    /// A closure that can fetch an arry of type `T` for the given page
    typealias FetchValuesClosure = (_ page: Int) -> Promise<PaginatedResults<T>>
    
    public weak var delegate: PaginationDelegate?
    
    private var values: [T] = []
    
    /// Holds the page numbers that have been fetched or are in-progress
    ///
    /// *Note*: Please use the `.addQueued(_:)` and `.removeQueued(_:)`
    /// methods to modify this value instead of accessing directly.
    private var fetched: Set<Int> = []
    
    /// Holds the page numbers that need to be fetched (because we only allow
    /// fetching one page at a time)
    ///
    /// *Note*: Please use the `.addQueued(_:)` and `.removeQueued(_:)`
    /// methods to modify this value instead of accessing directly.
    private var fetchQueue: Set<Int> = []
    
    private var paginatedCounts: PaginatedCounts = PaginatedCounts(totalCount: 0, totalPages: 0, currentPage: 0, perPage: 0)
    
    enum FetchStatus {
        case idle
        case fetching(page: Int)
    }

    private var fetchStatus: FetchStatus = .idle
    
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
    
    public func fetchValues(at indexPaths: [IndexPath]) {
        let firstPage: Int
        let lastPage: Int
        
        if indexPaths.isEmpty {
            // Fetch the first page
            firstPage = 1
            lastPage = firstPage
        } else {
            firstPage = (indexPaths.first!.item / paginatedCounts.perPage) + 1
            lastPage = ((indexPaths.last ?? indexPaths.first!).item / paginatedCounts.perPage) + 1
        }
        
        let rangeOfPages = (firstPage...max(firstPage, lastPage))
        addQueued(rangeOfPages)
        
        guard let nextPage = fetchQueue.sorted().first, !fetched.contains(nextPage) else {
            // This page was already fetched or is in-progress
            rangeOfPages.forEach(removeQueued)
            return
        }
        
        switch fetchStatus {
        case .idle:
            // First, remove the page we're about to fetch from the queue
            removeQueued(nextPage)
            // Then, allow the fetch to proceed
            break
            
        case .fetching:
            // Wait for the in-progress fetch to finish
            return
        }
        
        if !self.needsFetching {
            guard paginatedCounts.totalPages > 0 && nextPage <= paginatedCounts.totalPages else {
                return
            }
        }
        
        fetchStatus = .fetching(page: nextPage)
        
        fetchPage(nextPage)
        
    }
    
    private func fetchPage(_ page: Int) {
        firstly {
            performFetch(page)
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
            guard let `self` = self else { return }
            
            func finalize() {
                self.fetchStatus = .idle
                self.needsFetching = false
            }
            
            if !self.fetchQueue.isEmpty {
                let nextPage = self.fetchQueue.sorted().first!
                self.removeQueued(nextPage)
                finalize()
                self.fetchPage(nextPage)
            } else {
                finalize()
            }
            
        }
    }
    
    private func addQueued(_ pages: ClosedRange<Int>) {
        fetchQueue = fetchQueue.union(pages).subtracting(fetched)
    }
    
    private func removeQueued(_ page: Int) {
        fetchQueue.remove(page)
        fetched.insert(page)
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
        let section = delegate?.tableViewSection() ?? 0
        return (startIndex..<endIndex).map { IndexPath(row: $0, section: section) }
    }
    
}

public protocol SectionedPaginationDelegate: class {
    
    /// A new page of data was retreived from the server.
    ///
    /// - Parameter newIndexPathsToReload: The new indexPaths, if any, that
    ///               need to be updated. If it's the first page of results
    ///               this parameter will be `nil`.
    func onFetchCompleted(
        deleteRows: [IndexPath],
        insertRows: [IndexPath],
        deleteSections: IndexSet,
        insertSections: IndexSet
    )
    
    /// An error occurred when trying to fetch a page of data.
    ///
    /// - Parameter error: The error returned from the server.
    func onFetchFailed(with error: Error)
    
}

/// A type that knows how to handle and fetch paged data from the network.
public protocol SectionedPaginatedType: class {
    associatedtype T: Equatable
    
    /// Whether the first page of results have been fetched or not.
    var needsFetching: Bool { get }
    
    /// The number of sections.
    var numberOfSections: Int { get }
    
    /// The title for the given section
    func title(for section: Int) -> String?
    
    /// The number of values for the given section.
    func numberOfRowsInSection(_ section: Int) -> Int
    
    /// A delegate that is responsible for doing something with the newly fetched
    /// paged data, or any errors that might be encountered
    var delegate: SectionedPaginationDelegate? { get set }
    
    var sections: [SectionedPaginated<T>.Section] { get }
    
    /// Obtain the value at the specified IndexPath.
    ///
    /// - Parameter indexPath: The IndexPath
    /// - Returns: The value if it has been fetched, or `nil`.
    func value(at indexPath: IndexPath) -> T?
    
    /// Determine whether the value at the given indexPath has been fetched.
    ///
    /// - Parameter indexPath: The indexPath to check
    /// - Returns: `true` if the item has not been fetched yet, otherwise `false`
    func isLoadingValue(at indexPath: IndexPath) -> Bool
    
    /// Informs the `PaginatedType` to fetch a new set of values; either the
    /// first page, or the next page. It is safe to call this method repeatedly
    /// in quick succession.
    func fetchValues(at indexPaths: [IndexPath])
    
}

/// A concrete type that exposes the `PaginatedType` API and implements
/// fetching paged data as necessary.
public class SectionedPaginated<T: Equatable>: SectionedPaginatedType {
    
    /// A closure that can fetch an arry of type `T` for the given page
    typealias FetchValuesClosure = (_ page: Int) -> Promise<PaginatedResults<T>>
    
    /// A closure that returns the full title of the section for the given item
    typealias SectionTitleFactory = (T) -> String
    
    /// A closure that sorts the given section titles
    typealias SectionSorting = (String?, String?) -> Bool // were not nil
    
    /// A closure that returns the index title for the given section title
    /// Ex: A seciton titled `Fruits` would typically have an index title of `F`
    typealias SectionIndexTitleFactory = (String) -> String
    
    public struct Section: Equatable, Collection {
        public let title: String? // was not nil
        public let indexTitle: String?
        public fileprivate(set) var items: [T?] // was not nil
        
        // Equatable
        
        public static func == (lhs: Section, rhs: Section) -> Bool {
            return lhs.title == rhs.title
        }
        
        // Collection
        
        public typealias Index = Int
        
        public var startIndex: Int {
            return items.startIndex
        }
        
        public var endIndex: Int {
            return items.endIndex
        }
        
        public subscript(i: Int) -> T? { // was not nil
            return items[i]
        }
        
        public func index(after i: Int) -> Int {
            return items.index(after: i)
        }
        
        /// Items that haven't been fetched yet are added to their own "loading"
        /// section at the bottom of the list. This computed propertly allows
        /// us to find or filter out the loading section as needed.
        fileprivate var isLoadingSection: Bool {
            return title == nil
        }
    }
    
    public weak var delegate: SectionedPaginationDelegate?
    
    public private(set) var sections: [Section] = []
    
    /// Holds the page numbers that have been fetched or are in-progress
    ///
    /// *Note*: Please use the `.addQueued(_:)` and `.removeQueued(_:)`
    /// methods to modify this value instead of accessing directly.
    private var fetched: Set<Int> = []
    
    /// Holds the page numbers that need to be fetched (because we only allow
    /// fetching one page at a time)
    ///
    /// *Note*: Please use the `.addQueued(_:)` and `.removeQueued(_:)`
    /// methods to modify this value instead of accessing directly.
    private var fetchQueue: Set<Int> = []
    
    private var paginatedCounts: PaginatedCounts = PaginatedCounts(totalCount: 0, totalPages: 0, currentPage: 0, perPage: 0)
    
    enum FetchStatus {
        case idle
        case fetching(page: Int)
    }
    
    private var fetchStatus: FetchStatus = .idle
    
    private let performFetch: FetchValuesClosure
    private let sectionTitleFactory: SectionTitleFactory
    private let sectionSorting: SectionSorting
    private let sectionIndexTitleFactory: SectionIndexTitleFactory?
    
    /// A `Pagination` must be initialized with a closure that knows how to fetch
    /// a page of data.
    ///
    /// - Parameter fetchValues: A closure that can fetch an arry data
    ///                          for the given page
    required init(
        fetchValues: @escaping FetchValuesClosure,
        sectionTitle: @escaping SectionTitleFactory,
        sectionSorting: @escaping SectionSorting = { (section1, section2) in
            guard let s1 = section1, let s2 = section2 else {
                return false
            }
            return s1.localizedCaseInsensitiveCompare(s2) == .orderedAscending
        },
        sectionIndexTitle: SectionIndexTitleFactory? = .none
    ) {
        self.performFetch = fetchValues
        self.sectionTitleFactory = sectionTitle
        self.sectionSorting = sectionSorting
        self.sectionIndexTitleFactory = sectionIndexTitle
    }
    
    public var numberOfSections: Int {
        return sections.count
    }
    
    public func title(for section: Int) -> String? {
        return sections[section].title
    }
    
    public func numberOfRowsInSection(_ section: Int) -> Int {
        return sections[section].items.count
    }
    
    public var needsFetching: Bool = true
    
    public func value(at indexPath: IndexPath) -> T? {
        return sections[indexPath.section].items[indexPath.item]
    }
    
    public func isLoadingValue(at indexPath: IndexPath) -> Bool {
        return sections[indexPath.section].isLoadingSection
    }
    
    public func fetchValues(at indexPaths: [IndexPath]) {
        let firstPage: Int
        let lastPage: Int
        
        if indexPaths.isEmpty {
            // Fetch the first page
            firstPage = 1
            lastPage = firstPage
        } else {
            func itemIndex(at indexPath: IndexPath) -> Int {
                return (0..<indexPath.section).map({ sections[$0].items.count }).reduce(0, +) + indexPath.item
            }
            
            firstPage = (itemIndex(at: indexPaths.first!) / paginatedCounts.perPage) + 1
            lastPage = (itemIndex(at: indexPaths.last ?? indexPaths.first!) / paginatedCounts.perPage) + 1
        }
        
        let rangeOfPages = (firstPage...max(firstPage, lastPage))
        addQueued(rangeOfPages)
        
        guard let nextPage = fetchQueue.sorted().first, !fetched.contains(nextPage) else {
            // This page was already fetched or is in-progress
            rangeOfPages.forEach(removeQueued)
            return
        }
        
        switch fetchStatus {
        case .idle:
            // First, remove the page we're about to fetch from the queue
            removeQueued(nextPage)
            // Then, allow the fetch to proceed
            break
            
        case .fetching:
            // Wait for the in-progress fetch to finish
            return
        }
        
        if !self.needsFetching {
            guard paginatedCounts.totalPages > 0 && nextPage <= paginatedCounts.totalPages else {
                return
            }
        }
        
        fetchStatus = .fetching(page: nextPage)
        
        fetchPage(nextPage)
        
    }
    
    private func fetchPage(_ page: Int) {
        firstly {
            performFetch(page)
        }.then { [weak self] result in
            guard let `self` = self else { return }
            
            let oldSections = self.sections
            
            self.paginatedCounts = result.counts
            
            let groups = Dictionary(grouping: result.values, by: self.sectionTitleFactory)
            
            // Remove the "loading" section before proceeding
            var newSections = self.sections.filter({ !$0.isLoadingSection })
            
            groups.forEach({ (title, items) in
                if let foundIndex = newSections.firstIndex(where: { $0.title == title }) {
                    var section = newSections[foundIndex]
                    section.items += items
                    newSections[foundIndex] = section
                } else {
                    newSections += [Section(
                        title: title,
                        indexTitle: self.sectionIndexTitleFactory?(title),
                        items: items
                    )]
                }
            })
            
            // Add the "loading" section back in
            let totalCount = result.counts.totalCount
            let totalLoaded = newSections.reduce(0) { (total, section) -> Int in
                return total + section.items.count
            }
            let totalRemaining = totalCount - totalLoaded
            if totalRemaining > 0 {
                var loadingSection = Section(title: nil, indexTitle: nil, items: [])
                (0..<totalRemaining).forEach({ (_) in
                    loadingSection.items.append(nil)
                })
                newSections.append(loadingSection)
            }
            
            self.sections = newSections
                .sorted(by: { self.sectionSorting($0.title, $1.title) })
            
            let diff = oldSections.nestedDiff(to: self.sections)
            
            var itemDeletions: [IndexPath] = []
            var itemInsertions: [IndexPath] = []
            var sectionDeletions: IndexSet = []
            var sectionInsertions: IndexSet = []
            
            diff.forEach { element in
                switch element {
                case let .deleteElement(at, section):
                    itemDeletions.append(IndexPath(item: at, section: section))
                case let .insertElement(at, section):
                    itemInsertions.append(IndexPath(item: at, section: section))
                case let .deleteSection(at):
                    sectionDeletions.insert(at)
                case let .insertSection(at):
                    sectionInsertions.insert(at)
                }
            }

            self.delegate?.onFetchCompleted(
                deleteRows: itemDeletions,
                insertRows: itemInsertions,
                deleteSections: sectionDeletions,
                insertSections: sectionInsertions
            )
        }.catch { [weak self] error in
            self?.delegate?.onFetchFailed(with: error)
        }.always { [weak self] in
            guard let `self` = self else { return }
            
            func finalize() {
                self.fetchStatus = .idle
                self.needsFetching = false
            }
            
            if !self.fetchQueue.isEmpty {
                let nextPage = self.fetchQueue.sorted().first!
                self.removeQueued(nextPage)
                finalize()
                self.fetchPage(nextPage)
            } else {
                finalize()
            }
        }
    }
    
    private func addQueued(_ pages: ClosedRange<Int>) {
        fetchQueue = fetchQueue.union(pages).subtracting(fetched)
    }
    
    private func removeQueued(_ page: Int) {
        fetchQueue.remove(page)
        fetched.insert(page)
    }
    
}
