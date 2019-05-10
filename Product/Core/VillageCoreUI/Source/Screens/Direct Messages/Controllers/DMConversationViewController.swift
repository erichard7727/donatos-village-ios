//
//  DMConversationViewController.swift
//  VillageCore
//
//  Created by Michael Miller on 2/12/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import Foundation
import UIKit
import SlackTextViewController
import Photos
import Alamofire
import AlamofireImage
import VillageCore
import SafariServices
import Promises

/// Direct message conversation view controller.
final class DMConversationViewController: SLKTextViewController {
    let MAX_UPLOAD_SIZE = 2097152

    var directMessageThread: VillageCore.Stream! {
        didSet {
            if directMessageThread.id != threadSocket?.stream.id {
                threadSocket = try? StreamSocket(stream: directMessageThread, delegate: self)
            }
        }
    }
    
    var threadSocket: StreamSocket?

    let fetchNewThreshold: Int = 1

    var imagePicker = UIImagePickerController()

    var contentIDsLoading = Set<String>()
    
    var scrollForPreviousMessagesEnabled = false
    let progressIndicator = UIActivityIndicatorView(style: .gray)
    
    var messageList: Messages = []
    
    var loadingMoreMessages: Bool = false
    
    var currentPage: Int = 1
    
    var firstLoad: Bool = true
    var reloadData: Bool = true
    fileprivate var mediaSelection: Bool = false


    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let tableView = self.tableView else {
            return
        }
        
        
        self.view.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)
        
        // Configure apperance, etc.
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44.0
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.contentInsetAdjustmentBehavior = .never
        
        // Default behaviors.
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack),
            StandardStreamEditingUIBehavior()
        ])
        
        // Update title.
        let currentUser = User.current
        if let directMessageThread = directMessageThread,
           let otherParticipants = directMessageThread.details?.closedParties.filter({ $0.id != currentUser.personId }).compactMap({ $0.displayName }),
            !otherParticipants.isEmpty {
            title = otherParticipants.joined(separator: ", ")
        } else {
            title = "Conversation"
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        
        /// Register NIB with tableview.
        let selfMessageNib = UINib(nibName: "DMConversationSelfMessageCell", bundle: Constants.bundle)
        let selfAttachmentNib = UINib(nibName: "DMConversationSelfAttachmentCell", bundle: Constants.bundle)
        let otherMessageNib = UINib(nibName: "DMConversationOtherMessageCell", bundle: Constants.bundle)
        let otherAttachmentNib = UINib(nibName: "DMConversationOtherAttachmentCell", bundle: Constants.bundle)
        
        tableView.register(selfMessageNib, forCellReuseIdentifier: "DMConversationSelfMessageCell")
        tableView.register(selfAttachmentNib, forCellReuseIdentifier: "DMConversationSelfAttachmentCell")
        tableView.register(otherMessageNib, forCellReuseIdentifier: "DMConversationOtherMessageCell")
        tableView.register(otherAttachmentNib, forCellReuseIdentifier: "DMConversationOtherAttachmentCell")
        
        NotificationCenter.default.addObserver(self, selector: #selector(returnFromBackground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //self.textInputbar.isTranslucent = false
        self.textInputbar.textView.keyboardType = .default
        
        if !mediaSelection {
            self.displayProgressFooterView()
            
            AnalyticsService.logEvent(name: "view_message", parameters: ["message_type": "direct_message_thread"])
            
            // Reload the current page to see if there is new data
            returnFromBackground()
        }
        
        self.mediaSelection = false
        
        NotificationCenter.default.post(name: Notification.Name.Stream.IsViewingDirectMessageConversation, object: self, userInfo: [
            Notification.Name.Stream.directMessageConversationKey: directMessageThread!,
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        scrollForPreviousMessagesEnabled = true
    }
    
    var isLayingOutSubviews = false
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        defer {
            isLayingOutSubviews = false
        }
        
        isLayingOutSubviews = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !mediaSelection {
            threadSocket?.closeConnection()
            
            NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
        }
        
        NotificationCenter.default.post(name: Notification.Name.Stream.IsViewingDirectMessageConversation, object: self, userInfo: [:])
    }
    
    @objc func returnFromBackground() {
        self.loadingMoreMessages = true
        
        firstly { () -> Promise<Messages> in
            if let message = messageList.first {
                return message.getMessagesAfter()
            } else {
                return directMessageThread.getMessages(page: currentPage)
            }
        }.then { [weak self] messages in
            guard let `self` = self, !messages.isEmpty else { return }
            
            self.messageList.insert(contentsOf: messages, at: 0)
            
            if self.firstLoad || self.reloadData {
                self.tableView?.reloadData()
                self.tableView?.reloadSections([0], with: .automatic)
            } else {
                let numberToInsert = self.messageList.count - (self.messageList.count - messages.count)
                var indexPaths = [IndexPath]()
                (0 ..< numberToInsert).enumerated().forEach({ (_, index) in
                    indexPaths.append(IndexPath(row: index, section: 0))
                })
                
                self.tableView?.insertRows(at: indexPaths, with: .automatic)
            }
            
            self.currentPage = self.currentPage + 1
        }.always { [weak self] in
            self?.loadingMoreMessages = false
            self?.firstLoad = false
            self?.reloadData = false
            self?.threadSocket?.establishConnection()
        }
    }
    
    deinit {
        print("deinit")
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let inset = scrollView.contentInset
        let y = offset.y + bounds.size.height - inset.bottom
        let h = size.height
        let reloadDistance: CGFloat = 10
        
        if y > h + reloadDistance {
            
            if !isLayingOutSubviews && !loadingMoreMessages && !firstLoad {
                loadingMoreMessages = true
                reloadData = true
                self.returnFromBackground()
            }
        }
    }
    
    func displayProgressFooterView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: (self.tableView?.frame.width)!, height: 44))
        progressIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        progressIndicator.center = headerView.center
        headerView.addSubview(progressIndicator)
        progressIndicator.bringSubviewToFront(headerView)
        progressIndicator.startAnimating()
        progressIndicator.alpha = 1
        headerView.backgroundColor = UIColor.white
        tableView?.tableFooterView = headerView
        tableView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -headerView.frame.height, right: 0)
    }
    
    // MARK: SLKTextViewController methods
    override func didPressLeftButton(_ sender: Any!) {
        
        super.didPressLeftButton(sender)
        
        let actionSheetController: UIAlertController = UIAlertController(
            title: "Attach Media",
            message: "Choose an image from the following options.",
            preferredStyle: .actionSheet
        )
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] action -> Void in
            guard let strongSelf = self else {
                return
            }
            // Dismissed
            strongSelf.mediaSelection = false
        }
        actionSheetController.addAction(cancelAction)
        
        // Camera Roll
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) {
            let takePictureAction: UIAlertAction = UIAlertAction(title: "Camera", style: .default) { [weak self] action -> Void in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.imagePicker.delegate = self
                strongSelf.imagePicker.sourceType = .camera;
                strongSelf.imagePicker.allowsEditing = false
                strongSelf.mediaSelection = true
                strongSelf.present(strongSelf.imagePicker, animated: true, completion: nil)
            }
            actionSheetController.addAction(takePictureAction)
        }
        
        // Photo Gallery
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.savedPhotosAlbum){
            let choosePictureAction: UIAlertAction = UIAlertAction(title: "Gallery", style: .default) { [weak self] action -> Void in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.imagePicker.delegate = self
                strongSelf.imagePicker.sourceType = .savedPhotosAlbum;
                strongSelf.imagePicker.allowsEditing = false
                strongSelf.mediaSelection = true
                strongSelf.present(strongSelf.imagePicker, animated: true, completion: nil)
            }
            actionSheetController.addAction(choosePictureAction)
        }
        
        present(actionSheetController, animated: true, completion: nil)
        
    }
    
    override func didPressRightButton(_ sender: Any!) {
        guard let text = textView.text, !text.isEmpty else { return }
        
        firstly { () -> Promise<(VillageCore.Stream, Person)> in
            User.current.getPerson().then { (self.directMessageThread, $0) }
        }.then { (group, author) -> Promise<Message> in
            return group.send(message: text.trimmingCharacters(in: .whitespacesAndNewlines), from: author)
        }.then { [weak self] message in
            self?.messageList.insert(message, at: 0)
            self?.tableView?.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }.catch { [weak self] error in
            let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
            self?.present(alert, animated: true, completion: nil)
        }
        
        super.didPressRightButton(sender)
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? DMConversationOtherMessageCell {
            cell.initializeCell()
        } else if let cell = cell as? DMConversationOtherAttachmentCell {
            cell.initializeCell()
        }
    }
}

// MARK: - StreamSocketDelegate

extension DMConversationViewController: StreamSocketDelegate {
    
    func streamSocket(_ streamSocket: StreamSocket, didReceiveMessage message: Message) {
        if message.author.id != User.current.personId {
            messageList.insert(message, at: 0)
            tableView?.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }
    }
    
    func streamSocket(_ streamSocket: StreamSocket, message messageId: String, wasLiked isLiked: Bool, by personId: Int) {
//        if let row = messageList.firstIndex(where: { $0.id == messageId }) {
//            var mutableMessage = messageList[row]
//            if personId == User.current.personId {
//                mutableMessage.isLiked = isLiked
//            }
//            if isLiked {
//                mutableMessage.likesCount = mutableMessage.likesCount + 1
//            } else {
//                mutableMessage.likesCount = max(mutableMessage.likesCount - 1, 0)
//            }
//
//            messageList[row] = mutableMessage
//            tableView?.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
//        }
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension DMConversationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        self.dismiss(animated: true, completion: { () -> Void in
            // Dismissed
            self.mediaSelection = false
        })
        
        firstly {
            User.current.getPerson()
        }.then { [weak self] author in
            guard let `self` = self else { return }
            
            if let imageURL = info[UIImagePickerController.InfoKey.phAsset] as? URL {
                let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [imageURL], options: nil)
                if let photo = fetchResult.firstObject {
                    PHImageManager.default().requestImageData(for: photo, options: nil, resultHandler: { data, name, orientation, info in
                        guard let imageData = data else {
                            let alert = UIAlertController.dismissable(title: "Error", message: "Could not publish message.")
                            self.present(alert, animated: true, completion: nil)
                            return
                        }
                        
                        var scaledImage: UIImage?
                        if !UIImage.containsAnimatedImage(data: imageData) {
                            if let image = UIImage(data: imageData), imageData.count > self.MAX_UPLOAD_SIZE {
                                let oldSize: CGSize = image.size
                                let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
                                scaledImage = UIImage(data: image.resizeImage(imageSize: newSize, image: image) as Data)
                            }
                        }
                        
                        let attachmentMessageText = "\(author.displayName ?? "User") uploaded a photo."
                        
                        var mimeType: String
                        
                        if let name = name {
                            if name.contains("gif") {
                                mimeType = "image/gif"
                            } else {
                                mimeType = "image/png"
                            }
                        } else {
                            mimeType = "image/png"
                        }
                        
                        let attachmentContent = scaledImage != nil ? scaledImage!.pngData()! : imageData
                        
                        let indexPath = IndexPath(row: self.messageList.count, section: 0)
                        
                        let placeholder = Message(
                            id: "",
                            author: author,
                            authorId: author.id,
                            authorDisplayName: author.displayName ?? "",
                            streamId: "",
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
                        
                        self.messageList.insert(placeholder, at: indexPath.row - self.messageList.count)
                        let insertionIndex = IndexPath(row: indexPath.row - self.messageList.count + 1, section: 0)
                        self.tableView?.insertRows(at: [insertionIndex], with: .automatic)
                        
                        firstly {
                            self.directMessageThread.send(
                                message: attachmentMessageText,
                                attachment: (attachmentContent, mimeType),
                                from: author,
                                progress: { [weak self] percentage in
                                    guard let `self` = self else { return }
                                    
                                    let updateIndex = IndexPath(row: indexPath.row - self.messageList.count + 1, section: 0)
                                    if let cell = self.tableView?.cellForRow(at: updateIndex) as? GroupMessageAttachmentCell {
                                        cell.percentageLabel.text = String(percentage)
                                    }
                                }
                            )
                        }.then { [weak self] message in
                            guard let `self` = self else { return }
                            
                            self.messageList[indexPath.row - self.messageList.count + 1] = message
                            let updateIndex = IndexPath(row: indexPath.row - self.messageList.count + 1, section: 0)
                            self.tableView?.reloadRows(at: [updateIndex], with: .automatic)
                        }.catch { [weak self] error in
                            guard let `self` = self else { return }
                            
                            let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
                            self.present(alert, animated: true, completion: nil)
                            self.messageList.remove(at: indexPath.row - self.messageList.count + 1)
                            let updateIndex = IndexPath(row: indexPath.row - self.messageList.count, section: 0)
                            self.tableView?.deleteRows(at: [updateIndex], with: .automatic)
                        }

                    })
                }
            } else if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                guard let imageData = image.pngData() else {
                    let alert = UIAlertController.dismissable(title: "Error", message: "Could not publish message!")
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                
                var scaledImage: UIImage?
                if imageData.count > self.MAX_UPLOAD_SIZE {
                    let oldSize: CGSize = image.size
                    let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
                    scaledImage = UIImage(data: image.resizeImage(imageSize: newSize, image: image) as Data)
                }
                
                let attachmentMessageText = "\(author.displayName ?? "User") uploaded a photo."
                
                let attachmentContent = scaledImage != nil ? scaledImage!.pngData()! : imageData
                
                let indexPath = IndexPath(row: self.messageList.count, section: 0)
                
                let placeholder = Message(
                    id: "",
                    author: author,
                    authorId: author.id,
                    authorDisplayName: author.displayName ?? "",
                    streamId: "",
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
                
                self.messageList.insert(placeholder, at: indexPath.row - self.messageList.count)
                let insertionIndex = IndexPath(row: indexPath.row - self.messageList.count + 1, section: 0)
                self.tableView?.insertRows(at: [insertionIndex], with: .automatic)
                
                firstly {
                    self.directMessageThread.send(
                        message: attachmentMessageText,
                        attachment: (attachmentContent, "image/png"),
                        from: author,
                        progress: { [weak self] percentage in
                            guard let `self` = self else { return }
                            
                            let updateIndex = IndexPath(row: indexPath.row - self.messageList.count + 1, section: 0)
                            if let cell = self.tableView?.cellForRow(at: updateIndex) as? GroupMessageAttachmentCell {
                                cell.percentageLabel.text = String(percentage)
                            }
                        }
                    )
                }.then { [weak self] message in
                    guard let `self` = self else { return }
                    
                    self.messageList[indexPath.row - self.messageList.count + 1] = message
                    let updateIndex = IndexPath(row: indexPath.row - self.messageList.count + 1, section: 0)
                    self.tableView?.reloadRows(at: [updateIndex], with: .automatic)
                }.catch { [weak self] error in
                    guard let `self` = self else { return }
                    
                    let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
                    self.present(alert, animated: true, completion: nil)
                    self.messageList.remove(at: indexPath.row - self.messageList.count + 1)
                    let updateIndex = IndexPath(row: indexPath.row - self.messageList.count, section: 0)
                    self.tableView?.deleteRows(at: [updateIndex], with: .automatic)
                }
            } else {
                return
            }
        }
    }
    
    @objc func imageHeld(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        
        let alert = UIAlertController(title: "Save", message: "Save image to library?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) in
            if let imageView = longPressGestureRecognizer.view as? UIImageView, let image = imageView.image {
                self.saveImage(image: image)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveImage(image: UIImage) {
        if let pngRepresentation = image.pngData(),
            let data = UIImage(data: pngRepresentation) {
            UIImageWriteToSavedPhotosAlbum(data, nil, nil, nil)
            
            let alert = UIAlertController.dismissable(title: "Success", message: "Image saved to album.")
            self.present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: UITableViewDatasource
extension DMConversationViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messageList[indexPath.row]
        
        if message.authorId == User.current.personId {
            if let attachment = message.attachment {
                let cell = tableView.dequeueReusableCell(withIdentifier: "DMConversationSelfAttachmentCell") as! DMConversationSelfAttachmentCell
                
                cell.transform = tableView.transform
                
                cell.configureMessage(message, didSelectLink: { link in
                    UIApplication.shared.open(link, options: [.universalLinksOnly: true], completionHandler: { (success) in
                        if !success {
                            // not a universal link or app not installed
                            let vc = SFSafariViewController(url: link)
                            self.present(vc, animated: true)
                        }
                    })
                })
                cell.percentageLabel.text = "0%"
                cell.percentageLabel.alpha = 1
                
                cell.selectionStyle = .none
                cell.attachmentImageView.image = nil
                cell.imageView?.tag = -1
                
                // MARK: Add content item stuff here
                //if there's a content id associated then make the image an icon(pdf, etc)
                
                if attachment.type == "image/gif" {
                    let imageCache = AutoPurgingImageCache()
                    
                    if let cachedImage = imageCache.image(withIdentifier: message.id) {
                        cell.configureAnimatedAttachment(cachedImage)
                    } else if let url = message.attachment?.url {
                        cell.showProgressIndicator(true)
                        
                        Alamofire.request(url, method: .get)
                            .downloadProgress { progress in
                                cell.percentageLabel.text = String(Int(progress.fractionCompleted * 100)) + "%"
                            }.responseImage { [weak self] response in
                                
                                guard let strongSelf = self else {
                                    return
                                }
                                cell.showProgressIndicator(false)
                                cell.percentageLabel.alpha = 0
                                guard let image = response.data else {
                                    return
                                }
                                
                                cell.attachmentImageView.tag = indexPath.row
                                let tapGestureRecognizer = UITapGestureRecognizer(target: strongSelf, action: #selector(strongSelf.imageTapped(tapGestureRecognizer:)))
                                tapGestureRecognizer.numberOfTapsRequired = 1
                                cell.attachmentImageView.isUserInteractionEnabled = true
                                cell.attachmentImageView.addGestureRecognizer(tapGestureRecognizer)
                                
                                if let attachmentImage = UIImage(animatedImageData: image as Data) {
                                    if cell.message?.id == message.id {
                                        imageCache.add(attachmentImage, withIdentifier: message.id)
                                        cell.configureAnimatedAttachment(attachmentImage)
                                    }
                                }
                        }
                    }
                } else {
                    if let attachment = message.attachment {
                        let filter = AspectScaledToFillSizeFilter(
                            size: CGSize(width: (attachment.width > 0 ? CGFloat(attachment.width) : cell.attachmentImageView.frame.width), height: (attachment.height > 0 ? CGFloat(attachment.height) : cell.attachmentImageView.frame.height))
                        )
                        cell.showProgressIndicator(true)
                        cell.attachmentImageView.af_setImage(
                            withURL: attachment.url,
                            filter: filter,
                            progress: {
                                progress in
                                cell.percentageLabel.text = String(Int(progress.fractionCompleted * 100)) + "%"
                            },
                            progressQueue: DispatchQueue.main,
                            imageTransition: UIImageView.ImageTransition.crossDissolve(0.35),
                            runImageTransitionIfCached: false, completion: {
                                [weak self] result in
                                guard let strongSelf = self else {
                                    return
                                }
                                
                                cell.showProgressIndicator(false)
                                cell.percentageLabel.alpha = 0
                                cell.attachmentImageView.tag = indexPath.row
                                let tapGestureRecognizer = UITapGestureRecognizer(target: strongSelf, action: #selector(strongSelf.imageTapped(tapGestureRecognizer:)))
                                tapGestureRecognizer.numberOfTapsRequired = 1
                                cell.attachmentImageView.isUserInteractionEnabled = true
                                cell.attachmentImageView.addGestureRecognizer(tapGestureRecognizer)
                                
                                let gestureRecognizer = UILongPressGestureRecognizer(target: strongSelf, action: #selector(strongSelf.imageHeld(longPressGestureRecognizer:)))
                                gestureRecognizer.minimumPressDuration = 0.5
                                cell.attachmentImageView.addGestureRecognizer(gestureRecognizer)
                        })
                    }
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "DMConversationSelfMessageCell") as! DMConversationSelfMessageCell
                
                cell.configureCell(message, didSelectLink: { link in
                    UIApplication.shared.open(link, options: [.universalLinksOnly: true], completionHandler: { (success) in
                        if !success {
                            // not a universal link or app not installed
                            let vc = SFSafariViewController(url: link)
                            self.present(vc, animated: true)
                        }
                    })
                })
                if let tableView = self.tableView {
                    cell.transform = tableView.transform
                }
                return cell
            }
        } else {
            if let attachment = message.attachment {
                let cell = tableView.dequeueReusableCell(withIdentifier: "DMConversationOtherAttachmentCell") as! DMConversationOtherAttachmentCell
                
                cell.transform = tableView.transform
                
                cell.configureMessage(message, didSelectLink: { link in
                    UIApplication.shared.open(link, options: [.universalLinksOnly: true], completionHandler: { (success) in
                        if !success {
                            // not a universal link or app not installed
                            let vc = SFSafariViewController(url: link)
                            self.present(vc, animated: true)
                        }
                    })
                })
                cell.percentageLabel.text = "0%"
                cell.percentageLabel.alpha = 1
                
                cell.selectionStyle = .none
                cell.attachmentImageView.image = nil
                cell.imageView?.tag = -1
                
                // MARK: Add content item stuff here
                //if there's a content id associated then make the image an icon(pdf, etc)
                
                if attachment.type == "image/gif" {
                    let imageCache = AutoPurgingImageCache()
                    
                    if let cachedImage = imageCache.image(withIdentifier: message.id) {
                        cell.configureAnimatedAttachment(cachedImage)
                    } else if let attachment = message.attachment {
                        cell.showProgressIndicator(true)
                        
                        Alamofire.request(attachment.url, method: .get)
                            .downloadProgress { progress in
                                cell.percentageLabel.text = String(Int(progress.fractionCompleted * 100)) + "%"
                            }.responseImage { [weak self] response in
                                
                                guard let strongSelf = self else {
                                    return
                                }
                                cell.showProgressIndicator(false)
                                cell.percentageLabel.alpha = 0
                                guard let image = response.data else {
                                    return
                                }
                                
                                cell.attachmentImageView.tag = indexPath.row
                                let tapGestureRecognizer = UITapGestureRecognizer(target: strongSelf, action: #selector(strongSelf.imageTapped(tapGestureRecognizer:)))
                                tapGestureRecognizer.numberOfTapsRequired = 1
                                cell.attachmentImageView.isUserInteractionEnabled = true
                                cell.attachmentImageView.addGestureRecognizer(tapGestureRecognizer)
                                
                                if let attachmentImage = UIImage(animatedImageData: image as Data) {
                                    if cell.message?.id == message.id {
                                        imageCache.add(attachmentImage, withIdentifier: message.id)
                                        cell.configureAnimatedAttachment(attachmentImage)
                                    }
                                }
                        }
                    }
                } else {
                    if let attachment = message.attachment {
                        let filter = AspectScaledToFillSizeFilter(
                            size: CGSize(width: (attachment.width > 0 ? CGFloat(attachment.width) : cell.attachmentImageView.frame.width), height: (attachment.height > 0 ? CGFloat(attachment.height) : cell.attachmentImageView.frame.height))
                        )
                        cell.showProgressIndicator(true)
                        cell.attachmentImageView.af_setImage(
                            withURL: attachment.url,
                            filter: filter,
                            progress: {
                                progress in
                                cell.percentageLabel.text = String(Int(progress.fractionCompleted * 100)) + "%"
                            },
                            progressQueue: DispatchQueue.main,
                            imageTransition: UIImageView.ImageTransition.crossDissolve(0.35),
                            runImageTransitionIfCached: false, completion: {
                                [weak self] result in
                                guard let strongSelf = self else {
                                    return
                                }
                                
                                cell.showProgressIndicator(false)
                                cell.percentageLabel.alpha = 0
                                cell.attachmentImageView.tag = indexPath.row
                                let tapGestureRecognizer = UITapGestureRecognizer(target: strongSelf, action: #selector(strongSelf.imageTapped(tapGestureRecognizer:)))
                                tapGestureRecognizer.numberOfTapsRequired = 1
                                cell.attachmentImageView.isUserInteractionEnabled = true
                                cell.attachmentImageView.addGestureRecognizer(tapGestureRecognizer)
                                
                                let gestureRecognizer = UILongPressGestureRecognizer(target: strongSelf, action: #selector(strongSelf.imageHeld(longPressGestureRecognizer:)))
                                gestureRecognizer.minimumPressDuration = 0.5
                                cell.attachmentImageView.addGestureRecognizer(gestureRecognizer)
                        })
                    }
                }
                
                if let url = message.author.avatarURL {
                    let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                        size: cell.avatarImageView.frame.size,
                        radius: cell.avatarImageView.frame.size.height / 2
                    )
                    
                    cell.avatarImageView.af_setImage(withURL: url, filter: filter)
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "DMConversationOtherMessageCell") as! DMConversationOtherMessageCell
                
                cell.configureCell(message, didSelectLink: { link in
                    UIApplication.shared.open(link, options: [.universalLinksOnly: true], completionHandler: { (success) in
                        if !success {
                            // not a universal link or app not installed
                            let vc = SFSafariViewController(url: link)
                            self.present(vc, animated: true)
                        }
                    })
                })
                if let tableView = self.tableView {
                    cell.transform = tableView.transform
                }
                if let url = message.author.avatarURL {
                    let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                        size: cell.avatarImageView.frame.size,
                        radius: cell.avatarImageView.frame.size.height / 2
                    )
                    
                    cell.avatarImageView.af_setImage(withURL: url, filter: filter)
                }
                
                return cell
            }
        }
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let imageView = tapGestureRecognizer.view as! UIImageView
        if imageView.tag != -1 {
            let indexPath = NSIndexPath(row: imageView.tag, section: 0)
            
            let message = messageList[indexPath.row]
            
            let controller = UIStoryboard(name: "Groups", bundle: Constants.bundle).instantiateViewController(withIdentifier: "MediaPreviewViewController") as! MediaPreviewViewController
            controller.modalPresentationStyle = .overCurrentContext
            controller.modalTransitionStyle = .crossDissolve
            controller.message = message
            
            if let navController = navigationController {
                controller.navHeight = navController.navigationBar.frame.height
            }
            
            if let cell = tableView?.cellForRow(at: indexPath as IndexPath) as? DMConversationSelfAttachmentCell {
                controller.image = cell.attachmentImageView.image
            } else if let cell = tableView?.cellForRow(at: indexPath as IndexPath) as? DMConversationOtherAttachmentCell {
                controller.image = cell.attachmentImageView.image
            }

            controller.isDirectMessage = true
            
            present(controller, animated: true, completion: nil)
        }
    }
    
    func scaleImage(_ attachmentImage: UIImage, desiredImageWidth: CGFloat) -> UIImage {
        let imageWidth = attachmentImage.size.width
        let widthScale = (desiredImageWidth / imageWidth) < 1.0 ? (desiredImageWidth / imageWidth) : 1.0
        
        let size = attachmentImage.size.applying(CGAffineTransform(scaleX: widthScale, y: widthScale))
        let hasAlpha = true
        let scale: CGFloat = 0.0
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        attachmentImage.draw(in: CGRect(origin: CGPoint.zero, size: size))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
}
