//
//  GroupStreamDataSource.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 5/13/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import SafariServices
import VillageCore
import Photos
import Alamofire
import AlamofireImage
import Promises

fileprivate let HEADER_HEIGHT_CONST: CGFloat = 200

class GroupStreamDataSource: StreamDataSource {

    var isUserSubscribed: Bool

    init(stream: VillageCore.Stream, isUserSubscribed: Bool) {
        self.isUserSubscribed = isUserSubscribed
        super.init(stream: stream)
    }
    
    override func configure(delegate: StreamDataSourceDelegate, viewController: StreamViewController, tableView: UITableView) {
        super.configure(delegate: delegate, viewController: viewController, tableView: tableView)
        
        let settingsButton = UIBarButtonItem(image: UIImage.named("settings")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(goToGroupSettings(_:)))
        viewController.navigationItem.rightBarButtonItem = settingsButton
        
        // Register Cells
        tableView.register(UINib(nibName: "GroupMessageCell", bundle: Constants.bundle), forCellReuseIdentifier: "GroupMessageCell")
        tableView.register(UINib(nibName: "GroupMessageAttachmentCell", bundle: Constants.bundle), forCellReuseIdentifier: "GroupMessageAttachmentCell")
        tableView.register(UINib(nibName: "GroupHeaderViewCell", bundle: Constants.bundle), forCellReuseIdentifier: "WelcomeCell")
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let superValue = super.tableView(tableView, numberOfRowsInSection: section)
        
        guard let section = Section(rawValue: section) else {
            assertionFailure()
            return superValue
        }
        
        switch section {
        case .oldMessages:
            return superValue + 1
            
        case .newMessages:
            return superValue
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let lastSectionIndex = tableView.numberOfSections - 1
        let lastRowIndex = tableView.numberOfRows(inSection: indexPath.section) - 1
        
        guard indexPath.section != lastSectionIndex || indexPath.row != lastRowIndex else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "WelcomeCell", for: indexPath) as! GroupHeaderViewCell
            cell.transform = tableView.transform
            
            let welcomeText = NSMutableAttributedString()
            welcomeText.append(NSAttributedString(string: "This is the beginning of the "))
            
            let groupNameAttributedString = NSMutableAttributedString(string: String(stream.name), attributes: [
                .font: UIFont(name: "ProximaNova-SemiBold", size: 17.0)!
            ])
            
            welcomeText.append(groupNameAttributedString)
            
            let numberMembers = stream.details?.memberCount ?? 0
            
            welcomeText.append(NSAttributedString(string: " group. It has \(numberMembers) "))
            welcomeText.append(NSAttributedString(string: numberMembers == 1 ? "member" : "members"))
            welcomeText.append(NSAttributedString(string: ", including you."))
            
            cell.descriptionLabel.attributedText = welcomeText
            
            if let details = stream.details, details.streamType == .closed && String(User.current.personId) != details.ownerId {
                let inviteAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: "ProximaNova-Semibold", size: 17.0)!,
                    .foregroundColor: UIColor.vlgGreen,
                    .underlineStyle: 0
                ]
                let inviteAttributedString = NSMutableAttributedString(string: "Only the creator can invite others", attributes: inviteAttributes)
                cell.inviteButton.setAttributedTitle(inviteAttributedString, for: .normal)
                cell.inviteButton.isEnabled = false
            }
            
            cell.delegate = self
            return cell
        }
        
        let msg = message(at: indexPath)
        if let message = msg, let attachment = message.attachment {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GroupMessageAttachmentCell") as! GroupMessageAttachmentCell
            cell.transform = tableView.transform
            cell.showProgressIndicator(true)
            cell.message = message
            cell.stream = stream
            
            cell.percentageLabel.text = "0%"
            cell.percentageLabel.alpha = 1
            cell.selectionStyle = .none
            cell.attachmentView.image = nil
            cell.imageView?.tag = -1
            
            cell.configureCellMessage(message)
            
            cell.didSelectPerson = { [weak self] person in
                firstly {
                    person.getDetails()
                }.then { [weak self] (personWithDetails) in
                    let vc = UIStoryboard(name: "Directory", bundle: Constants.bundle).instantiateViewController(withIdentifier: "PersonProfileViewController") as! PersonProfileViewController
                    vc.person = person
                    vc.delegate = self
                    self?.viewController.show(vc, sender: self)
                }
            }

            cell.showMoreOptions = { [weak self] in
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(
                    title: "Report as Inappropriate",
                    style: .destructive,
                    handler: { [weak self] (_) in
                        let confirm = UIAlertController(
                            title: "Confirm Report as Inappropriate",
                            message: "Are you sure you want to report this message as inappropriate? It will be removed immedaitely and your name will be recorded as the reporter.",
                            preferredStyle: .alert
                        )
                        confirm.addAction(UIAlertAction(
                            title: "Report as Inappropriate",
                            style: .destructive,
                            handler: { (_) in
                                // Flagging the message will cause the stream socket to receive
                                // the deleted message and remove the message in the UI shortly
                                _ = msg?.flag()
                        }
                        ))
                        confirm.addAction(UIAlertAction(
                            title: "Cancel",
                            style: .cancel,
                            handler: nil
                        ))
                        self?.viewController.present(confirm, animated: true, completion: nil)
                    }
                ))
                alert.addAction(UIAlertAction(
                    title: "Cancel",
                    style: .cancel,
                    handler: nil
                ))
                self?.viewController.present(alert, animated: true, completion: nil)
            }
            
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
                            
                            cell.attachmentView.tag = indexPath.integerRepresentation
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
                            cell.attachmentView.tag = indexPath.integerRepresentation
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
            cell.selectionStyle = .none
            cell.stream = stream
            
            cell.didSelectLink = { link in
                UIApplication.shared.open(link, options: [.universalLinksOnly: true], completionHandler: { (success) in
                    if !success {
                        // not a universal link or app not installed
                        let vc = SFSafariViewController(url: link)
                        self.viewController.present(vc, animated: true)
                    }
                })
            }
            
            cell.didSelectPerson = { [weak self] person in
                firstly {
                    person.getDetails()
                }.then { [weak self] (personWithDetails) in
                    let vc = UIStoryboard(name: "Directory", bundle: Constants.bundle).instantiateViewController(withIdentifier: "PersonProfileViewController") as! PersonProfileViewController
                    vc.person = person
                    vc.delegate = self
                    self?.viewController.show(vc, sender: self)
                }
            }

            cell.showMoreOptions = { [weak self] in
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(
                    title: "Report as Inappropriate",
                    style: .destructive,
                    handler: { [weak self] (_) in
                        let confirm = UIAlertController(
                            title: "Confirm Report as Inappropriate",
                            message: "Are you sure you want to report this message as inappropriate? It will be removed immedaitely and your name will be recorded as the reporter.",
                            preferredStyle: .alert
                        )
                        confirm.addAction(UIAlertAction(
                            title: "Report as Inappropriate",
                            style: .destructive,
                            handler: { (_) in
                                // Flagging the message will cause the stream socket to receive
                                // the deleted message and remove the message in the UI shortly
                                _ = msg?.flag()
                            }
                        ))
                        confirm.addAction(UIAlertAction(
                            title: "Cancel",
                            style: .cancel,
                            handler: nil
                        ))
                        self?.viewController.present(confirm, animated: true, completion: nil)
                    }
                ))
                alert.addAction(UIAlertAction(
                    title: "Cancel",
                    style: .cancel,
                    handler: nil
                ))
                self?.viewController.present(alert, animated: true, completion: nil)
            }
            
            if let message = msg {
                cell.configureCell(message)
            }
            
            return cell
        }
    }
    
}

private extension GroupStreamDataSource {
    
    func message(at indexPath: IndexPath) -> Message? {
        let message: Message?
        switch Section(rawValue: indexPath.section) {
        case .oldMessages?:
            message = oldMessages.value(at: indexPath.row)
        case .newMessages?:
            message = newMessages[indexPath.row]
        case .none:
            assertionFailure()
            message = nil
        }
        return message
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        guard let imageView = tapGestureRecognizer.view as? UIImageView, imageView.tag != -1 else {
            assertionFailure()
            return
        }
        
        let indexPath = imageView.tag.indexPathRepresentation
        guard let message = message(at: indexPath) else {
            return
        }
        
        let controller = UIStoryboard(name: "Groups", bundle: Constants.bundle).instantiateViewController(withIdentifier: "MediaPreviewViewController") as! MediaPreviewViewController
        controller.modalPresentationStyle = .overCurrentContext
        controller.modalTransitionStyle = .crossDissolve
        controller.message = message
        
        if let navController = viewController?.navigationController {
            controller.navHeight = navController.navigationBar.frame.height
        }
        
        if let cell = tableView.cellForRow(at: indexPath as IndexPath) as? GroupMessageAttachmentCell {
            controller.image = cell.attachmentView.image
        }
        
        controller.isDirectMessage = false
        
        viewController.present(controller, animated: true, completion: nil)
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
        
        viewController.present(alert, animated: true, completion: nil)
    }
    
    func saveImage(image: UIImage) {
        if let pngRepresentation = image.pngData(),
            let data = UIImage(data: pngRepresentation) {
            
            UIImageWriteToSavedPhotosAlbum(data, nil, nil, nil)
            let alert = UIAlertController.dismissable(title: "Success", message: "Image saved to album.")
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func goToGroupSettings(_ sender: Any? = nil) {
        let vc = UIStoryboard(name: "Groups", bundle: Constants.bundle).instantiateViewController(withIdentifier: "GroupSettingsController") as! GroupSettingsController
        vc.group = stream
        vc.isUserSubscribed = isUserSubscribed
        vc.delegate = self
        viewController.show(vc, sender: self)
    }
    
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension GroupStreamDataSource {
    
    static let MAX_UPLOAD_SIZE = 2097152
    
    override func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        viewController.dismiss(animated: true, completion: {
            self.viewController.mediaSelection = false
        })
        
        firstly {
            User.current.getPerson()
        }.then { [weak self] author in
            guard let `self` = self else { return }
            
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                guard let imageData = image.vlg_orientedUp().pngData() else {
                    let alert = UIAlertController.dismissable(title: "Error", message: "There was a problem sending your message.")
                    self.viewController.present(alert, animated: true, completion: nil)
                    return
                }
                
                self.send(attachment: (imageData, "image/png"))
            } else {
                let alert = UIAlertController.dismissable(title: "Error", message: "There was a problem sending your message.")
                self.viewController.present(alert, animated: true, completion: nil)
            }
        }
    }
    
}

extension GroupStreamDataSource: GroupSettingsControllerDelegate {
    
    func didLeave(_ group: VillageCore.Stream, controller: GroupSettingsController) {
        let vc = UIStoryboard(name: "OtherGroupsListViewController", bundle: Constants.bundle).instantiateInitialViewController() as! OtherGroupsListViewController
        viewController.sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
        viewController.sideMenuController?.hideMenu()
    }

    func didSubscribeTo(_ group: VillageCore.Stream, controller: GroupSettingsController) {
        isUserSubscribed = true
        viewController.navigationController?.popViewController(animated: true)
    }
    
}

extension GroupStreamDataSource: GroupHeaderViewDelegate {
    
    func inviteButtonPressed() {
        viewController.view.endEditing(true)
        
        let vc = UIStoryboard(name: "Groups", bundle: Constants.bundle).instantiateViewController(withIdentifier: "SelectPeopleViewController") as! SelectPeopleViewController
        vc.title = String(format: "Invite to %@", stream.name)
        vc.delegate = self
        vc.groupMembers = stream.details?.closedParties ?? []
        viewController.show(vc, sender: self)
    }
    
}

extension GroupStreamDataSource: SelectPeopleViewControllerDelegate {
    
    func didSelectPeople(_ people: People) {
        firstly {
            stream.invite(people)
        }.then { [weak self] in
            let alert = UIAlertController(title: "Success", message: "The invitation was sent.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Dismiss", style: .default, handler: { [weak vc = self?.viewController] action in
                vc?.navigationController?.popViewController(animated: true)
            })
            alert.addAction(action)
            self?.viewController.present(alert, animated: true, completion: nil)
        }.catch { [weak self] error in
            let alert = UIAlertController(title: "Error", message: "There was a problem sending the invitation. Please try again.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Dismiss", style: .default, handler: { [weak vc = self?.viewController] action in
                vc?.navigationController?.popViewController(animated: true)
            })
            alert.addAction(action)
            self?.viewController.present(alert, animated: true, completion: nil)
        }
    }
    
}

extension GroupStreamDataSource: PersonProfileViewControllerDelegate {
    
    func shouldShowAndStartDirectMessage(_ directMessage: VillageCore.Stream, controller: ContactPersonViewController) {
        let dataSource = DirectMessageStreamDataSource(stream: directMessage)
        let vc = StreamViewController(dataSource: dataSource)
        viewController.sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
    }
    
}
