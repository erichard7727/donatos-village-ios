//
//  StreamViewController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 5/13/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import SlackTextViewController
import SafariServices
import VillageCore
import Promises

class StreamViewController: SLKTextViewController {
    
    // MARK: - Public Properties
    
    var mediaSelection: Bool = false
    
    // MARK: - Private Properties
    
    private var dataSource: StreamDataSource
    
    private var imagePicker = UIImagePickerController()
    
    private var background: UIImageView?
    
    // MARK: - Init
    
    init(dataSource: StreamDataSource) {
        self.dataSource = dataSource
        super.init(tableViewStyle: .plain)!
        self.dataSource.configure(delegate: self, viewController: self, tableView: tableView)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var tableView: UITableView {
        return super.tableView!
    }
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack),
            StandardStreamEditingUIBehavior()
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
        } else {
            self.title = dataSource.stream.name
        }
        
        self.textInputbar.textView.keyboardType = .default
        
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
                NotificationCenter.default.post(
                    name: Notification.Name.Stream.IsViewingDirectMessageConversation,
                    object: self,
                    userInfo: [
                        Notification.Name.Stream.directMessageConversationKey: dataSource.stream,
                    ]
                )
            }
        }
        
        dataSource.streamSocket?.establishConnection()
        
        self.mediaSelection = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        background?.frame = tableView.frame
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !dataSource.hasMessages {
            self.textView.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !mediaSelection {
            dataSource.streamSocket?.closeConnection()
        }
        
        NotificationCenter.default.post(name: Notification.Name.Stream.IsViewingDirectMessageConversation, object: self, userInfo: [:])
    }
    
    // MARK: - SLKTextViewController Overrides
    
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
    
    override func didPressRightButton(_ sender: Any!) {
        guard let text = textView.text, !text.isEmpty else { return }
        
        dataSource.send(message: text.trimmingCharacters(in: .whitespacesAndNewlines))
        
        super.didPressRightButton(sender)
    }
    
    deinit {
        print("deinit")
    }
}

// MARK: - Private Methods

private extension StreamViewController {

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
