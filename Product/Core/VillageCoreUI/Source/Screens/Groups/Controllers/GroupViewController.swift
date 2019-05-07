//
//  GroupViewController.swift
//  VillageCore
//
//  Created by Colin on 12/10/15.
//  Copyright © 2015 Dynamit. All rights reserved.
//

import Foundation
import SlackTextViewController
import Photos
import Alamofire
import AlamofireImage
import VillageCore
import SafariServices
import Promises

//import SwiftyJSON // TO BE REMOVED AT A LATER TIME

/// Delegated events from group view controller.
protocol GroupViewControllerDelegate: class {
    func didLeaveGroup(_ group: VillageCore.Stream, controller: GroupViewController)
}

/// View controller for displaying a group chat.
final class GroupViewController: SLKTextViewController {
    let MAX_UPLOAD_SIZE = 2097152
    
    @IBOutlet weak var settingsBarButtonItem: UIBarButtonItem!
    
    weak var delegate: GroupViewControllerDelegate?
    
    var group: VillageCore.Stream!

    fileprivate var isScrolling = false

    fileprivate let fetchNewThreshold: Int = 1
    
    fileprivate var imagePicker = UIImagePickerController()

    fileprivate var contentIDsLoading = Set<String>()
    
    fileprivate var scrollForPreviousMessagesEnabled = false
    
    fileprivate let HEADER_HEIGHT_CONST: CGFloat = 480
    
    fileprivate var messageList: Messages = []
    
    fileprivate var loadingMoreMessages: Bool = false
    
    fileprivate var currentPage: Int = 1
    
    fileprivate var groupHasBeenPopulated: Bool = false
    fileprivate var mediaSelection: Bool = false
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var emptyStateLabel: UILabel!
    
    fileprivate var firstLoad: Bool = true
    fileprivate var reloadData: Bool = true
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let tableView = self.tableView else {
            return
        }
        
        tableView.bounces = true
        
        tableView.backgroundColor = UIColor.white

        let backgroundImage = UIImage.named("app-background")!
        let backgroundImageView = UIImageView(image: backgroundImage)
        backgroundImageView.contentMode = .scaleAspectFill
        
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let topConstraint = NSLayoutConstraint(item: backgroundImageView, attribute: .top, relatedBy: .equal, toItem: tableView, attribute: .top, multiplier: 1.0, constant: 0.0)
        let leadingConstraint = NSLayoutConstraint(item: backgroundImageView, attribute: .leading, relatedBy: .equal, toItem: tableView, attribute: .leading, multiplier: 1.0, constant: 0.0)
        let trailingConstraint = NSLayoutConstraint(item: backgroundImageView, attribute: .trailing, relatedBy: .equal, toItem: tableView, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        let bottomConstraint = NSLayoutConstraint(item: backgroundImageView, attribute: .bottom, relatedBy: .equal, toItem: tableView, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        
        view.insertSubview(backgroundImageView, belowSubview: tableView)
        
        view.addConstraints([topConstraint, leadingConstraint, trailingConstraint, bottomConstraint])

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44.0
        
        self.view.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)

        // Configure apperance, etc.
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack),
            StandardStreamEditingUIBehavior()
        ])
        
        AnalyticsService.logEvent(name: "view_group", parameters: ["screen": "group", "group_id": self.group.id])
        
        // Register NIB with tableview.
        let nib = UINib(nibName: "GroupMessageCell", bundle: Constants.bundle)
        let nib2 = UINib(nibName: "GroupMessageAttachmentCell", bundle: Constants.bundle)
        tableView.register(nib, forCellReuseIdentifier: "GroupMessageCell")
        tableView.register(nib2, forCellReuseIdentifier: "GroupMessageAttachmentCell")

        settingsBarButtonItem.image = UIImage.named("settings")?.withRenderingMode(.alwaysTemplate)
        
        emptyStateLabel.alpha = 0
        self.view.bringSubviewToFront(activityIndicator)
        self.view.bringSubviewToFront(emptyStateLabel)
        
        NotificationCenter.default.addObserver(self, selector: #selector(returnFromBackground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopWebsocket), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
    }
    
    func getGroup() {
        firstly {
            self.group.getDetails()
        }.then { [weak self] group in
            guard let `self` = self else { return }
            self.groupHasBeenPopulated = true
            self.group = group
            self.title = group.name
            if let details = group.details, self.messageList.count < 50 && details.memberCount > 0 {
                self.displayWelcomeBannerUI()
            }
        }
    }
    
    func displayWelcomeBannerUI() {
        if let bundle = Constants.bundle.loadNibNamed("GroupHeaderView", owner: self, options: nil), let groupHeaderView = bundle[0] as? GroupHeaderView {
            
            let welcomeText = NSMutableAttributedString()
            
            welcomeText.append(NSAttributedString(string: "This is the beginning of the "))
            
            let boldAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "ProximaNova-SemiBold", size: 17.0)!
            ]
            
            let groupNameAttributedString = NSMutableAttributedString(string: String(group.name), attributes: boldAttributes)
            
            welcomeText.append(groupNameAttributedString)
            
            let numberMembers = group.details?.memberCount ?? 0
            
            welcomeText.append(NSAttributedString(string: " group. It has \(numberMembers) "))
            welcomeText.append(NSAttributedString(string: numberMembers == 1 ? "member" : "members"))
            welcomeText.append(NSAttributedString(string: ", including you."))
            
            groupHeaderView.descriptionLabel.attributedText = welcomeText
            
            if let details = group.details, details.streamType == .closed && String(User.current.personId) != details.ownerId {
                let inviteAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: "ProximaNova-Semibold", size: 17.0)!,
                    .foregroundColor: UIColor.vlgGreen,
                    .underlineStyle: 0
                ]
                let inviteAttributedString = NSMutableAttributedString(string: "Only the creator can invite others", attributes: inviteAttributes)
                groupHeaderView.inviteButton.setAttributedTitle(inviteAttributedString, for: .normal)
                groupHeaderView.inviteButton.isEnabled = false
            }
            
            groupHeaderView.transform = CGAffineTransform(scaleX: 1.0, y: -1.0)
            
            groupHeaderView.delegate = self
            
            tableView?.tableFooterView = groupHeaderView
            tableView?.backgroundColor = UIColor.clear
        }
    }
    
    func displayFooterView() {
        // Append white space to bottom of tableView
        if let tableView = self.tableView {
            let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: HEADER_HEIGHT_CONST))
            headerView.backgroundColor = UIColor.white
            tableView.tableHeaderView = headerView
        }
    }
    
    func displayProgressHeaderView() {
        if let tableView = self.tableView {
            let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 44))
            let progressIndicator = UIActivityIndicatorView(style: .gray)
            progressIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            progressIndicator.center = headerView.center
            headerView.addSubview(progressIndicator)
            progressIndicator.bringSubviewToFront(headerView)
            progressIndicator.startAnimating()
            headerView.backgroundColor = UIColor.white
            tableView.tableFooterView = headerView
        }
    }
    
    func loadMoreMessages() {
        loadingMoreMessages = true
        
        firstly { () -> Promise<Messages> in
            return group.getMessages(page: currentPage)
        }.then { [weak self] messages in
            guard let `self` = self else { return }
            
//            if self.context.currentMessageStream != self.group {
//                self.startWebsocket()
//            }
            
            if !messages.isEmpty {
                if messages.count < 50  {
                    self.displayWelcomeBannerUI()
                }
                self.messageList.append(contentsOf: messages)
                if self.firstLoad || self.reloadData {
                    self.tableView?.reloadData()
                    self.tableView?.reloadSections([0], with: .automatic)
                    self.firstLoad = false
                    self.reloadData = false
                } else {
                    var indexPaths = [IndexPath]()
                    for i in (self.currentPage * 50 + 1)...(self.messageList.count + (self.currentPage * 50)) {
                        indexPaths.append(IndexPath(row: i, section: 0))
                    }
                    
                    self.tableView?.insertRows(at: indexPaths, with: .none)
                    
                    self.tableView?.scrollToRow(at: indexPaths[3], at: .bottom, animated: true)
                }
                
                self.currentPage = self.currentPage + 1
            }
        }.always { [weak self] in
            self?.getGroup()
            self?.loadingMoreMessages = false
            self?.activityIndicator.stopAnimating()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        //self.textInputbar.isTranslucent = false
        self.textInputbar.textView.keyboardType = .default
        
        if !mediaSelection {
            loadMoreMessages()
            
            #warning("TODO - This might be useful for sockets? context.currentMessageStream")
//            context.currentMessageStream = group
            
            displayFooterView()
        }
        
        self.mediaSelection = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollForPreviousMessagesEnabled = true
        
//        context.sendMessage = { [weak self] message in
//            guard let strongSelf = self else {
//                return
//            }
//
//            if Int(message.ownerId) != strongSelf.context.session?.person?.id {
//                strongSelf.messageList.insert(message, at: 0)
//                let indexPath = NSIndexPath(row: 0, section: 0)
//                strongSelf.tableView?.insertRows(at: [indexPath as IndexPath], with: .automatic)
//            }
//        }
//
//        context.likeMessage = { [weak self] messageId, liked, changedBy in
//            guard let strongSelf = self else {
//                return
//            }
//
//            if let index = strongSelf.messageList.index(where: { $0.id == messageId }) {
//                var message = strongSelf.messageList[index]
//
//                if changedBy == strongSelf.context.session?.person?.id {
//                    if liked {
//                        message.hasUserLikedMessage = true
//                    } else {
//                        message.hasUserLikedMessage = false
//                    }
//                }
//
//                if liked {
//                    message.likesCount += 1
//                } else {
//                    message.likesCount -= 1
//                }
//
//                strongSelf.messageList[index] = message
//
//                let indexPath = IndexPath(row: index, section: 0)
//                if let tableView = strongSelf.tableView, indexPath.row < tableView.numberOfRows(inSection: 0) {
//                    strongSelf.tableView?.reloadRows(at: [indexPath], with: .none)
//                }
//            }
//        }
    }
    
    var isLayingOutSubviews = false
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        isLayingOutSubviews = true
        
        defer {
            isLayingOutSubviews = false
        }
        
        var navHeight: CGFloat = 0
        if let navController = navigationController {
            navHeight = navController.navigationBar.frame.height + UIApplication.shared.statusBarFrame.height
        }
        // Adjust inset to ignore scrolling on "header" so it will give the illusion of bouncing with white background
        tableView?.contentInset = UIEdgeInsets(top: -HEADER_HEIGHT_CONST, left: 0, bottom: navHeight, right: 0)
        tableView?.scrollIndicatorInsets = UIEdgeInsets(top: -HEADER_HEIGHT_CONST, left: 0, bottom: navHeight, right: 0)
        
        guard let groupHeaderView = tableView?.tableFooterView as? GroupHeaderView else {
            return
        }
        
        if groupHeaderView.contentView.frame.height != groupHeaderView.frame.height {
            var headerViewFrame = groupHeaderView.frame
            headerViewFrame.size.height = groupHeaderView.contentView.frame.size.height
            groupHeaderView.frame = headerViewFrame
            tableView?.tableFooterView = groupHeaderView
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !mediaSelection {
            self.stopWebsocket()
            
            NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
            
//            context.sendMessage = nil
//            context.likeMessage = nil
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GroupSettings" {
            view.endEditing(true)
            
            guard let controller = segue.destination as? GroupSettingsController else {
                fatalError("GroupSettingsController not found")
            }
            
            controller.group = group
            controller.delegate = self
        } else if segue.identifier == "InviteToGroup" {
            view.endEditing(true)
            
            guard let controller = segue.destination as? SelectPeopleViewController else {
                fatalError("MemberSelectionController not found")
            }
            
            guard let group = self.group else {
                fatalError("group not set")
            }
            
            controller.title = String(format: "Invite to %@", group.name)
            controller.delegate = self
            controller.groupMembers = group.details?.closedParties ?? []
        }
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
                strongSelf.imagePicker.delegate = strongSelf
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
            User.current.getPerson().then { (self.group, $0) }
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
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isScrolling = false
        self.visibleCellsShouldRasterize(isScrolling)
    }
    
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity == CGPoint.zero{
            isScrolling = false
            self.visibleCellsShouldRasterize(isScrolling)
        }
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
        self.visibleCellsShouldRasterize(isScrolling)
        
    }
    
    func visibleCellsShouldRasterize(_ aBool:Bool) {
        if let tableView = self.tableView {
            for cell in tableView.visibleCells as [UITableViewCell] {
                cell.layer.shouldRasterize = aBool;
                cell.layer.rasterizationScale = UIScreen.main.scale
            }
        }
    }
    
    @objc func returnFromBackground() {
        firstly { () -> Promise<Messages> in
            if let message = messageList.first {
                return message.getMessagesAfter()
            } else {
                return group.getMessages()
            }
        }.then { [weak self] messages in
            guard let `self` = self else { return }
            
            self.messageList.insert(contentsOf: messages.reversed(), at: 0)
            self.tableView?.insertRows(
                at: Array(repeating: IndexPath(row: 0, section: 0), count: messages.count),
                with: .none
            )
            
            self.loadingMoreMessages = false
            self.firstLoad = false
            self.startWebsocket()
            self.getGroup()
        }
    }
    
    func startWebsocket() {
        #warning("TODO - how to start websocket?")
//        context.currentMessageStream = group
//        context.startMessageWebsocket(streamID: group.id, messageFilter: .all)
    }
    
    @objc func stopWebsocket() {
        #warning("TODO - how to stop websocket?")
//        context.currentMessageStream = nil
//        context.stopMessageWebsocket()
    }
}

extension GroupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        self.dismiss(animated: true, completion: { () -> Void in
            self.mediaSelection = false
        })

        firstly {
            User.current.getPerson()
        }.then { [weak self] author in
            guard let `self` = self else { return }

            if let imageURL = info[UIImagePickerController.InfoKey.phAsset] as? URL {
                let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [imageURL], options: nil)
                if let photo = fetchResult.firstObject {
                    PHImageManager.default().requestImageData(for: photo, options: nil, resultHandler: { [weak self] data, name, orientation, info in
                        guard let `self` = self else { return }

                        guard let imageData = data else {
                            let alert = UIAlertController.dismissable(title: "Error", message: "There was a problem sending your message.")
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

                        let attachmentMessageText = (author.displayName ?? "User") + " uploaded a photo."

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
                            self.group.send(
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
                    let alert = UIAlertController.dismissable(title: "Error", message: "Could not publish message.")
                    self.present(alert, animated: true, completion: nil)
                    return
                }

                var scaledImage: UIImage?
                if imageData.count > self.MAX_UPLOAD_SIZE {
                    let oldSize: CGSize = image.size
                    let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
                    scaledImage = UIImage(data: image.resizeImage(imageSize: newSize, image: image) as Data)
                }

                let attachmentMessageText = (author.displayName ?? "User") + " uploaded a photo."

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
                    self.group.send(
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
}

// MARK: UITableViewDatasource
extension GroupViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messageList[indexPath.row]
        
        if let attachment = message.attachment {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GroupMessageAttachmentCell") as! GroupMessageAttachmentCell

            cell.transform = tableView.transform

            cell.showProgressIndicator(true)
            cell.message = message
            cell.stream = group

            cell.percentageLabel.text = "0%"
            cell.percentageLabel.alpha = 1
            cell.selectionStyle = .none
            cell.attachmentView.image = nil
            cell.imageView?.tag = -1

            cell.configureCellMessage(message)

            // MARK: Add content item stuff here
            //if there's a content id associated then make the image an icon(pdf, etc)

            if let url = message.author.avatarURL {
                let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                    size: cell.avatarImageView.frame.size,
                    radius: cell.avatarImageView.frame.size.height / 2
                )

                cell.avatarImageView.af_setImage(withURL: url, filter: filter)
            }

            if attachment.type == "image/gif" {
                let imageCache = AutoPurgingImageCache()

                if let cachedImage = imageCache.image(withIdentifier: message.id) {
                    cell.configureCellAnimatedAttachment(cachedImage)
                } else if let url = message.attachment?.url {

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

                        cell.attachmentView.tag = indexPath.row
                        let tapGestureRecognizer = UITapGestureRecognizer(target: strongSelf, action: #selector(strongSelf.imageTapped(tapGestureRecognizer:)))
                        tapGestureRecognizer.numberOfTapsRequired = 1
                        cell.attachmentView.isUserInteractionEnabled = true
                        cell.attachmentView.addGestureRecognizer(tapGestureRecognizer)

                        if let attachmentImage = UIImage(animatedImageData: image as Data) {
                            if cell.message?.id == message.id {
                                imageCache.add(attachmentImage, withIdentifier: message.id)
                                cell.configureCellAnimatedAttachment(attachmentImage)
                            }
                        }
                    }
                }
            } else {
                if let attachment = message.attachment {
                    let filter = AspectScaledToFillSizeFilter(
                        size: CGSize(width: (attachment.width > 0 ? CGFloat(attachment.width) : cell.attachmentView.frame.width), height: (attachment.height > 0 ? CGFloat(attachment.height) : cell.attachmentView.frame.height))
                    )
                    
                    cell.attachmentView.af_setImage(
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
                            cell.attachmentView.tag = indexPath.row
                            let tapGestureRecognizer = UITapGestureRecognizer(target: strongSelf, action: #selector(strongSelf.imageTapped(tapGestureRecognizer:)))
                            tapGestureRecognizer.numberOfTapsRequired = 1
                            cell.attachmentView.isUserInteractionEnabled = true
                            cell.attachmentView.addGestureRecognizer(tapGestureRecognizer)

                            let gestureRecognizer = UILongPressGestureRecognizer(target: strongSelf, action: #selector(strongSelf.imageHeld(longPressGestureRecognizer:)))
                            gestureRecognizer.minimumPressDuration = 0.5
                            cell.attachmentView.addGestureRecognizer(gestureRecognizer)
                    })

                }
            }

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GroupMessageCell") as! GroupMessageCell
            
            cell.transform = tableView.transform
            if let tableView = self.tableView {
                cell.transform = tableView.transform
            }
            cell.stream = group
            cell.didSelectLink = { link in
                UIApplication.shared.open(link, options: [.universalLinksOnly: true], completionHandler: { (success) in
                    if !success {
                        // not a universal link or app not installed
                        let vc = SFSafariViewController(url: link)
                        self.present(vc, animated: true)
                    }
                })
            }
            cell.selectionStyle = .none
            cell.configureCell(message)
            
            return cell
        }
    }
}

// MARK: UITableViewDelegate
extension GroupViewController {

    
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
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let imageView = tapGestureRecognizer.view as! UIImageView
        if imageView.tag != -1 {
            let indexPath = NSIndexPath(row: imageView.tag, section: 0)
            
            let message = messageList[indexPath.row] 
            
            let controller = UIStoryboard(name: "Groups", bundle: Constants.bundle).instantiateViewController(withIdentifier: "MediaPreviewViewController") as! MediaPreviewViewController
            controller.modalPresentationStyle = .overCurrentContext
            controller.modalTransitionStyle = .crossDissolve
            
            
            if let navController = navigationController {
                controller.navHeight = navController.navigationBar.frame.height
            }
            
            controller.message = message
            
            if let cell = tableView?.cellForRow(at: indexPath as IndexPath) as? GroupMessageAttachmentCell {
                controller.image = cell.attachmentView.image
            }
            
            controller.isDirectMessage = false
            
            present(controller, animated: true, completion: nil)
        }
    }
    
    @objc func imageHeld(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        
        let alert = UIAlertController(title: "Save", message: "Save image to library?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak self] (action: UIAlertAction) in
            guard let strongSelf = self else {
                return
            }
            if let imageView = longPressGestureRecognizer.view as? UIImageView, let image = imageView.image {
                strongSelf.saveImage(image: image)
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
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? GroupMessageCell {
            cell.initializeCellContents()
        } else if let cell = cell as? GroupMessageAttachmentCell {
            cell.initializeCellContents()
        }
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
                self.loadMoreMessages()
            }
        }
    }
}

extension GroupViewController: GroupSettingsControllerDelegate {
    
    func shouldLeaveGroup(_ group: VillageCore.Stream, controller: GroupSettingsController) {
        delegate?.didLeaveGroup(group, controller: self)
    }
    
}

extension GroupViewController: GroupHeaderViewDelegate {
    func inviteButtonPressed() {
        performSegue(withIdentifier: "InviteToGroup", sender: nil)
    }
}

extension GroupViewController: SelectPeopleViewControllerDelegate {
    
    func didSelectPeople(_ people: People) {
        firstly {
            group.invite(people).then { self.group }
        }.then { group in
            group.getDetails()
        }.then { [weak self] group in
            self?.group = group
            
            let alert = UIAlertController(title: "Success", message: "The invitation was sent.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Dismiss", style: .default, handler: { action in
                self?.navigationController?.popViewController(animated: true)
            })
            alert.addAction(action)
            self?.present(alert, animated: true, completion: nil)
        }.catch { [weak self] error in
            let alert = UIAlertController(title: "Error", message: "There was a problem sending the invitation. Please try again.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Dismiss", style: .default, handler: { action in
                self?.navigationController?.popViewController(animated: true)
            })
            alert.addAction(action)
            self?.present(alert, animated: true, completion: nil)
        }
    }
}
