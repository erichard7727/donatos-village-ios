//
//  StreamDataSource.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 5/13/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore
import Promises

protocol StreamDataSourceDelegate: class {
    func imageTapped(_ image: UIImage, in message: Message)
    func imageHeld(_ image: UIImage)
}

class StreamDataSource: NSObject {
    
    // MARK: - Public
    
    var hasMessages: Bool {
        return (oldMessages.totalCount + newMessages.count) > 0
    }
    
    init(stream: VillageCore.Stream) {
        self.stream = stream
        oldMessages = stream.getMessagesPaginated()
        super.init()
        oldMessages.delegate = self
    }
    
    func send(message: String, errorHandler: @escaping (() -> Void)) {
        firstly { () -> Promise<(VillageCore.Stream, Person)> in
            User.current.getPerson().then { (self.stream, $0) }
        }.then { (stream, author) -> Promise<Message> in
            return stream.send(message: message, from: author)
        }.then { [weak self] message in
            guard
                let `self` = self
            else { return }
            
            self.upsert(message, in: self.tableView, scrollToMessage: false)
        }.catch { [weak self] error in
            let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
            self?.viewController.present(alert, animated: true, completion: {
                errorHandler()
            })
        }
    }
    
    func send(attachment: (data: Data, mimeType: String)) {
        let placeholderId = UUID().uuidString
        
        firstly { () -> Promise<(VillageCore.Stream, Person)> in
            User.current.getPerson().then { (self.stream, $0) }
        }.then { (stream, author) -> Promise<Message> in
            var scaledImage: UIImage?
            if !UIImage.containsAnimatedImage(data: attachment.data) {
                if let image = UIImage(data: attachment.data), attachment.data.count > DirectMessageStreamDataSource.MAX_UPLOAD_SIZE {
                    let oldSize: CGSize = image.size
                    let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
                    scaledImage = UIImage(data: image.resizeImage(imageSize: newSize, image: image) as Data)
                }
            }
            
            let attachmentMessageText = "\(author.displayName ?? "User") uploaded a photo."
            
            let attachmentContent = scaledImage != nil ? scaledImage!.pngData()! : attachment.data
            
            let placeholder = Message(
                id: placeholderId,
                author: author,
                authorId: author.id,
                authorDisplayName: author.displayName ?? "",
                streamId: stream.id,
                body: attachmentMessageText,
                isLiked: false,
                likesCount: 0,
                created: "",
                updated: "",
                isSystem: false,
                attachment: Message.Attachment(
                    content: "",
                    type: "",
                    title: "",
                    width: 250,
                    height: 250,
                    url: URL(string: "/")! // https://via.placeholder.com/250.png?text=%20
                )
            )
            
            self.newMessages.insert(placeholder, at: 0)
            self.tableView.insertRows(at: [IndexPath(row: 0, section: Section.newMessages.rawValue)], with: .automatic)
            
            return self.stream.send(
                message: attachmentMessageText,
                attachment: (attachmentContent, attachment.mimeType),
                from: author,
                progress: { [weak self] percentage in
                    guard
                        let `self` = self,
                        let placeholderIndex = self.newMessages.firstIndex(where: { $0.id == placeholderId })
                    else { return }
                    
                    let updateIndex = IndexPath(row: placeholderIndex, section: Section.newMessages.rawValue)
                    if let cell = self.tableView.cellForRow(at: updateIndex) as? GroupMessageAttachmentCell {
                        cell.percentageLabel.text = String(percentage)
                    }
                }
            )
        }.then { [weak self] message in
            guard
                let `self` = self,
                let placeholderIndex = self.newMessages.firstIndex(where: { $0.id == placeholderId })
            else { return }
            
            self.upsert(message, placeholderIndex: placeholderIndex, in: self.tableView, scrollToMessage: false)
        }.catch { [weak self] error in
            guard
                let `self` = self,
                let placeholderIndex = self.newMessages.firstIndex(where: { $0.id == placeholderId })
            else { return }
            
            let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
            self.viewController.present(alert, animated: true, completion: nil)
            self.newMessages.remove(at: placeholderIndex)
            let updateIndex = IndexPath(row: placeholderIndex, section: Section.newMessages.rawValue)
            self.tableView.deleteRows(at: [updateIndex], with: .automatic)
        }
    }
    
    func configure(delegate: StreamDataSourceDelegate, viewController: StreamViewController, tableView: UITableView) {
        self.delegate = delegate
        self.viewController = viewController
        self.tableView = tableView
        
        // Appearance / Behavior
        tableView.dataSource = self
        tableView.prefetchDataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44.0
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .interactive
    }
    
    private(set) var oldMessages: Paginated<Message> {
        didSet {
            oldMessages.delegate = self
        }
    }
    
    private(set) var newMessages: Messages = []

    /// The "offset" between the oldMessages totalCount from the server
    /// and the "new messages" we're keeping track of locally in
    /// Section.newMessages
    private var newMessagesCountOffet = 0

    lazy var streamSocket: StreamSocket? = {
        return try? StreamSocket(stream: stream, delegate: self)
    }()
    
    // MARK: - Private
    
    enum Section: Int, CaseIterable {
        case newMessages = 0
        case oldMessages
    }
    
    let stream: VillageCore.Stream
    
    private(set) weak var delegate: StreamDataSourceDelegate?
    
    private(set) var viewController: StreamViewController!
    
    private(set) var tableView: UITableView!
    
}

// MARK: - Public Methods

extension StreamDataSource {
    
    
    
}

// MARK: - Private Methods

private extension StreamDataSource {
    
    func upsert(_ message: Message, placeholderIndex: Array<Message>.Index? = nil, in tableView: UITableView, scrollToMessage: Bool = true) {
        if let placeholderIndex = placeholderIndex {
            let updateIndexPath = IndexPath(row: placeholderIndex, section: Section.newMessages.rawValue)
            if self.newMessages.contains(where: { $0.id == message.id }) {
                // The new item already exists; remove placeholder
                self.newMessages.remove(at: placeholderIndex)
                self.tableView.deleteRows(at: [updateIndexPath], with: .none)
            } else {
                // Replace the placeholder
                self.newMessages[placeholderIndex] = message
                self.tableView.reloadRows(at: [updateIndexPath], with: .none)
            }
        } else {
            if let index = newMessages.firstIndex(where: { $0.id == message.id }) {
                newMessages[index] = message
                tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            } else {
                newMessages.insert(message, at: 0)
                tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            }
        }

        if scrollToMessage {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
    
}

// MARK: - UITableViewDataSource

extension StreamDataSource: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .oldMessages?:
            return oldMessages.totalCount - newMessagesCountOffet
            
        case .newMessages?:
            return newMessages.count
            
        case .none:
            assertionFailure()
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError("Subclasses must override \(#function)!")
    }
    
}

// MARK: - UITableViewDataSourcePrefetching

extension StreamDataSource: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let containsLoadingCells = indexPaths
            .filter({ $0.section == Section.oldMessages.rawValue })
            .contains(where: oldMessages.isLoadingValue)
        
        if containsLoadingCells {
            oldMessages.fetchValues(at: indexPaths)
        }
    }
    
}

// MARK: - UITableViewDelegate

extension StreamDataSource: UITableViewDelegate { }

// MARK: - PaginationDelegate

extension StreamDataSource: PaginationDelegate {
    
    func onFetchCompleted(with newIndexPathsToReload: [IndexPath]?) {
        guard let newIndexPathsToReload = newIndexPathsToReload else {
            // Show the first page of results
//            loadingMessagesContainer.isHidden = true
            tableView.reloadData()
            return
        }
        
        // Every time new data is fetched or refreshed, we need to account
        // for the new messages we're keeping track of in Section.newMessages
        // so that the tableView's counts remain correct before reloading data
        // otherwise there will be a crash.
        newMessagesCountOffet = newMessagesCountOffet + (newMessages.count - newMessagesCountOffet)
        
        // Reload the next page of results
        let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows ?? []
        let indexPathsToReload = oldMessages.visibleIndexPathsToReload(indexPathsForVisibleRows, intersecting: newIndexPathsToReload)
        tableView.reloadRows(at: indexPathsToReload, with: .automatic)
        
        streamSocket?.establishConnection()
    }
    
    func onFetchFailed(with error: Error) {
        let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
        viewController.present(alert, animated: true, completion: nil)
    }
    
    func tableViewSection() -> Int {
        return Section.oldMessages.rawValue
    }
    
}

// MARK: - StreamSocketDelegate

extension StreamDataSource: StreamSocketDelegate {
    
    func streamSocket(_ streamSocket: StreamSocket, didReceiveMessage message: Message) {
        upsert(message, in: tableView)
    }
    
    func streamSocket(_ streamSocket: StreamSocket, message messageId: String, wasLiked isLiked: Bool, by personId: Int) { }

    func streamSocket(_ streamSocket: StreamSocket, didDeleteMessage message: Message) {
        if let index = newMessages.firstIndex(where: { $0.id == message.id }) {
            newMessages.remove(at: index)
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        } else {
            streamSocket.closeConnection()
            newMessages.removeAll()
            newMessagesCountOffet = 0
            oldMessages = stream.getMessagesPaginated()
            oldMessages.fetchValues(at: [])
        }
    }
    
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension StreamDataSource: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        fatalError("Subclasses must override \(#function)!")
    }
    
}
