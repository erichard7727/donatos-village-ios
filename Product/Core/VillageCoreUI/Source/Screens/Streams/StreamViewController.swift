//
//  StreamViewController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 5/13/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import MessageViewController
import SafariServices
import VillageCore
import Promises

class StreamViewController: MessageViewController {
    
    // MARK: - Public Properties
    
    var mediaSelection: Bool = false
    
    // MARK: - Private Properties
    
    private var dataSource: StreamDataSource
    
    private var imagePicker = UIImagePickerController()
    
    private var background: UIImageView?

    private var groupSubscriptionCTA: GroupSubscriptionCTA?
    
    // MARK: - Init
    
    init(dataSource: StreamDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
        self.dataSource.configure(delegate: self, viewController: self, tableView: tableView)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.transform = CGAffineTransform(scaleX: 1, y: -1)
        return tv
    }()
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)

        // Configure MessageView
        borderColor = .gray
        messageView.font = UIFont(name: "ProximaNova-Regular", size: 16)!
        messageView.maxLineCount = 6

        messageView.addButton(target: self, action: #selector(didPressLeftButton), position: .left)
        messageView.setButton(icon: UIImage.named("add-icon")?.withRenderingMode(.alwaysTemplate), for: .normal, position: .left)
        messageView.setButton(inset: 10, position: .left)
        messageView.leftButtonTint = .vlgGray
        messageView.showLeftButton = true

        messageView.textView.textContainerInset = UIEdgeInsets(top: 9, left: 8, bottom: 9, right: 16)
        messageView.textView.placeholderText = "Message"
        messageView.textView.placeholderTextColor = .lightGray

        messageView.addButton(target: self, action: #selector(didPressRightButton), position: .right)
        messageView.setButton(title: "Send", for: .normal, position: .right)
        messageView.setButton(font: UIFont(name: "ProximaNova-Semibold", size: 16)!, position: .right)
        messageView.setButton(inset: 10, position: .right)
        messageView.rightButtonTint = .vlgRed

        setup(scrollView: tableView)
        
        navigationItem.largeTitleDisplayMode = .never
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack),
        ])
        
        if dataSource.stream.id.lowercased().starts(with: "stream") {
            background = UIImageView(image: UIImage.named("app-background"))
            tableView.backgroundView = background
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Update title.
        if dataSource.stream.id.lowercased().starts(with: "dm") {
            let currentUser = User.current
            let otherParticipants = dataSource.stream.details?.closedParties.filter({ $0.id != currentUser.personId }).compactMap({ $0.displayName })
            self.title = otherParticipants?.joined(separator: ", ") ?? "Conversation"
            self.setMessageView(hidden: false, animated: false)
        } else {
            self.title = dataSource.stream.name
            let isUserSubscribed = (dataSource as? GroupStreamDataSource)?.isUserSubscribed ?? false
            setGroupSubscriptionCTAHidden(isUserSubscribed, animated: false)
        }
        
        if dataSource.oldMessages.needsFetching {
//            loadingGroupsContainer.isHidden = false
            dataSource.oldMessages.fetchValues(at: [])
        } else {
            if !mediaSelection {
//                loadingGroupsContainer.isHidden = false
                // TODO: Figure out how to call fetchMessagesAfter
                dataSource.oldMessages.fetchValues(at: [])
            } else {
//                loadingGroupsContainer.isHidden = true
            }
        }
        
        dataSource.streamSocket?.establishConnection()
        
        NotificationCenter.default.post(
            name: Notification.Name.Stream.isViewingDirectMessageConversation,
            object: self,
            userInfo: [
                Notification.Name.Stream.streamKey: dataSource.stream,
            ]
        )
        
        self.mediaSelection = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        background?.frame = tableView.frame

        let topInset = groupSubscriptionCTA?.bounds.height ?? 0
        tableView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !dataSource.hasMessages {
            messageView.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !mediaSelection {
            dataSource.streamSocket?.closeConnection()
        }
        
        NotificationCenter.default.post(name: Notification.Name.Stream.isViewingDirectMessageConversation, object: self, userInfo: [:])
    }
    
    @objc func didPressLeftButton() {

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
                strongSelf.imagePicker.delegate = self?.dataSource
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
                strongSelf.imagePicker.delegate = self?.dataSource
                strongSelf.imagePicker.sourceType = .savedPhotosAlbum;
                strongSelf.imagePicker.allowsEditing = false
                strongSelf.mediaSelection = true
                strongSelf.present(strongSelf.imagePicker, animated: true, completion: nil)
            }
            actionSheetController.addAction(choosePictureAction)
        }
        
        present(actionSheetController, animated: true, completion: nil)
        
    }
    
    @objc func didPressRightButton() {
        guard !messageView.text.isEmpty else { return }

        let text = messageView.text
        messageView.text = ""

        dataSource.send(
            message: text.trimmingCharacters(in: .whitespacesAndNewlines),
            errorHandler: { [weak self] in
                self?.messageView.text = text
            }
        )
    }
}

// MARK: - Private Methods

private extension StreamViewController {

    func makeGroupSubscriptionCTA() -> GroupSubscriptionCTA {
        let cta = GroupSubscriptionCTA(
            stream: self.dataSource.stream,
            responseHandler: { [weak self] (response) in
                switch response {
                case .didSubscribe(let success):
                    if success {
                        self?.setGroupSubscriptionCTAHidden(true, animated: false)
                    } else {
                        let alert = UIAlertController(
                            title: "Subscription Error",
                            message: "There was a problem subscribing to this group. Please try again.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                        self?.present(alert, animated: true, completion: nil)
                    }

                case .viewDetails(let stream):
                    let vc = UIStoryboard(name: "Groups", bundle: Constants.bundle).instantiateViewController(withIdentifier: "GroupSettingsController") as! GroupSettingsController
                    vc.group = stream
                    vc.delegate = self?.dataSource as? GroupStreamDataSource
                    self?.show(vc, sender: self)

                case .fetchDetailsErrored:
                    let alert = UIAlertController(
                        title: "Group Error",
                        message: "There was a problem fetching details for this group. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        )
        cta.translatesAutoresizingMaskIntoConstraints = false
        return cta
    }

    func setGroupSubscriptionCTAHidden(_ isHidden: Bool, animated: Bool) {
        if !isHidden {
            let groupSubscriptionCTA = makeGroupSubscriptionCTA()
            groupSubscriptionCTA.alpha = 0
            self.groupSubscriptionCTA = groupSubscriptionCTA
            view.addSubview(groupSubscriptionCTA)
            view.addConstraints([
                view.leadingAnchor.constraint(equalTo: groupSubscriptionCTA.leadingAnchor),
                view.bottomAnchor.constraint(equalTo: groupSubscriptionCTA.bottomAnchor),
                view.trailingAnchor.constraint(equalTo: groupSubscriptionCTA.trailingAnchor),
            ])
        }
        UIView.animate(
            withDuration: animated ? 0.25 : 0,
            animations: {
                self.groupSubscriptionCTA?.alpha = isHidden ? 0 : 1
            },
            completion: { _ in
                if isHidden {
                    self.groupSubscriptionCTA?.removeFromSuperview()
                    self.groupSubscriptionCTA = nil
                }
            }
        )
        setMessageView(hidden: !isHidden, animated: animated)
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

// MARK: - StreamDataSourceDelegate

extension StreamViewController: StreamDataSourceDelegate {
    
    func imageTapped(_ image: UIImage, in message: Message) {
        let controller = UIStoryboard(name: "Groups", bundle: Constants.bundle).instantiateViewController(withIdentifier: "MediaPreviewViewController") as! MediaPreviewViewController
        controller.modalPresentationStyle = .overCurrentContext
        controller.modalTransitionStyle = .crossDissolve
        controller.message = message
        controller.image = image
        controller.isDirectMessage = dataSource is DirectMessageStreamDataSource
        
        if let navController = navigationController {
            controller.navHeight = navController.navigationBar.frame.height
        }
        present(controller, animated: true, completion: nil)
    }
    
    func imageHeld(_ image: UIImage) {
        let alert = UIAlertController(title: "Save", message: "Save image to library?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) in
            self.saveImage(image: image)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
}
