//
//  DirectMessageStreamDataSource.swift
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

class DirectMessageStreamDataSource: StreamDataSource {
    
    override func configure(delegate: StreamDataSourceDelegate, viewController: StreamViewController, tableView: UITableView) {
        super.configure(delegate: delegate, viewController: viewController, tableView: tableView)
        
        // Register Cells
        let selfMessageNib = UINib(nibName: "DMConversationSelfMessageCell", bundle: Constants.bundle)
        let selfAttachmentNib = UINib(nibName: "DMConversationSelfAttachmentCell", bundle: Constants.bundle)
        let otherMessageNib = UINib(nibName: "DMConversationOtherMessageCell", bundle: Constants.bundle)
        let otherAttachmentNib = UINib(nibName: "DMConversationOtherAttachmentCell", bundle: Constants.bundle)
        
        tableView.register(selfMessageNib, forCellReuseIdentifier: "DMConversationSelfMessageCell")
        tableView.register(selfAttachmentNib, forCellReuseIdentifier: "DMConversationSelfAttachmentCell")
        tableView.register(otherMessageNib, forCellReuseIdentifier: "DMConversationOtherMessageCell")
        tableView.register(otherAttachmentNib, forCellReuseIdentifier: "DMConversationOtherAttachmentCell")
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let message = message(at: indexPath) {
            let userIsAuthor = message.author.id == User.current.personId
            switch (userIsAuthor, message.attachment) {
            case (true, .some(let attachment)):
                let cell = tableView.dequeueReusableCell(withIdentifier: "DMConversationSelfAttachmentCell") as! DMConversationSelfAttachmentCell
                cell.transform = tableView.transform
                
                cell.configureMessage(message, didSelectLink: { [weak self] link in
                    guard let `self` = self else { return }
                    UIApplication.shared.open(link, options: [.universalLinksOnly: true], completionHandler: { (success) in
                        if !success {
                            // not a universal link or app not installed
                            let vc = SFSafariViewController(url: link)
                            self.viewController.present(vc, animated: true)
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
                                
                                cell.attachmentImageView.tag = indexPath.integerRepresentation
                                
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
                            size: CGSize(
                                width: (attachment.width > 0 ? CGFloat(attachment.width) : cell.attachmentImageView.frame.width),
                                height: (attachment.height > 0 ? CGFloat(attachment.height) : cell.attachmentImageView.frame.height)
                            )
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
                                cell.attachmentImageView.tag = indexPath.integerRepresentation
                                
                                let tapGestureRecognizer = UITapGestureRecognizer(target: strongSelf, action: #selector(strongSelf.imageTapped(tapGestureRecognizer:)))
                                tapGestureRecognizer.numberOfTapsRequired = 1
                                cell.attachmentImageView.isUserInteractionEnabled = true
                                cell.attachmentImageView.addGestureRecognizer(tapGestureRecognizer)
                                
                                let gestureRecognizer = UILongPressGestureRecognizer(target: strongSelf, action: #selector(strongSelf.imageHeld(longPressGestureRecognizer:)))
                                gestureRecognizer.minimumPressDuration = 0.5
                                cell.attachmentImageView.addGestureRecognizer(gestureRecognizer)
                            }
                        )
                    }
                }
                
                return cell
            
            case (true, .none):
                let cell = tableView.dequeueReusableCell(withIdentifier: "DMConversationSelfMessageCell") as! DMConversationSelfMessageCell
                cell.transform = tableView.transform
                cell.configureCell(message, didSelectLink: { [weak self] link in
                    guard let `self` = self else { return }
                    UIApplication.shared.open(link, options: [.universalLinksOnly: true], completionHandler: { (success) in
                        if !success {
                            // not a universal link or app not installed
                            let vc = SFSafariViewController(url: link)
                            self.viewController.present(vc, animated: true)
                        }
                    })
                })
                return cell
                
            case (false, .some(let attachment)):
                let cell = tableView.dequeueReusableCell(withIdentifier: "DMConversationOtherAttachmentCell") as! DMConversationOtherAttachmentCell
                cell.transform = tableView.transform
                
                cell.configureMessage(message, didSelectLink: { [weak self] link in
                    UIApplication.shared.open(link, options: [.universalLinksOnly: true], completionHandler: { (success) in
                        if !success {
                            // not a universal link or app not installed
                            let vc = SFSafariViewController(url: link)
                            self?.viewController.present(vc, animated: true)
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
                                
                                cell.attachmentImageView.tag = indexPath.integerRepresentation
                                
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
                            runImageTransitionIfCached: false, completion: { [weak self] result in
                                guard let strongSelf = self else {
                                    return
                                }
                                
                                cell.showProgressIndicator(false)
                                cell.percentageLabel.alpha = 0
                                cell.attachmentImageView.tag = indexPath.integerRepresentation
                                
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
                
            case (false, .none):
                let cell = tableView.dequeueReusableCell(withIdentifier: "DMConversationOtherMessageCell") as! DMConversationOtherMessageCell
                cell.transform = tableView.transform
                cell.configureCell(message, didSelectLink: { [weak self] link in
                    UIApplication.shared.open(link, options: [.universalLinksOnly: true], completionHandler: { (success) in
                        if !success {
                            // not a universal link or app not installed
                            let vc = SFSafariViewController(url: link)
                            self?.viewController.present(vc, animated: true)
                        }
                    })
                })
                if let url = message.author.avatarURL {
                    let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                        size: cell.avatarImageView.frame.size,
                        radius: cell.avatarImageView.frame.size.height / 2
                    )
                    
                    cell.avatarImageView.af_setImage(withURL: url, filter: filter)
                }
                return cell
            }
        } else {
            // Content is loading
            let cell = tableView.dequeueReusableCell(withIdentifier: "DMConversationSelfMessageCell") as! DMConversationSelfMessageCell
            cell.transform = tableView.transform
            DMConversationCellConfiguartor().configure(cell, forDisplaying: nil, viewController: viewController)
            return cell
        }
    }
    
}

private extension DirectMessageStreamDataSource {
    
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
        
        if let cell = tableView.cellForRow(at: indexPath as IndexPath) as? DMConversationSelfAttachmentCell {
            controller.image = cell.attachmentImageView.image
        } else if let cell = tableView.cellForRow(at: indexPath as IndexPath) as? DMConversationOtherAttachmentCell {
            controller.image = cell.attachmentImageView.image
        }
        
        controller.isDirectMessage = true
        
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
    
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension DirectMessageStreamDataSource {
    
    static let MAX_UPLOAD_SIZE = 2097152
    
    override func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        viewController.dismiss(animated: true, completion: {
            self.viewController.mediaSelection = false
        })
        
        firstly {
            User.current.getPerson()
        }.then { [weak self] author in
            guard let `self` = self else { return }
            
            if let imageURL = info[UIImagePickerController.InfoKey.phAsset] as? URL,
               let photo = PHAsset.fetchAssets(withALAssetURLs: [imageURL], options: nil).firstObject {
                PHImageManager.default().requestImageData(for: photo, options: nil, resultHandler: {
                    data, name, orientation, info in
                        
                    guard let imageData = data else {
                        let alert = UIAlertController.dismissable(title: "Error", message: "Could not publish message.")
                        self.viewController.present(alert, animated: true, completion: nil)
                        return
                    }
                    
                    var mimeType: String {
                        if let name = name {
                            if name.contains("gif") {
                                return "image/gif"
                            } else {
                                return "image/png"
                            }
                        } else {
                            return "image/png"
                        }
                    }
                    
                    self.send(attachment: (imageData, mimeType))
                })
            } else if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                guard let imageData = image.pngData() else {
                    let alert = UIAlertController.dismissable(title: "Error", message: "Could not publish message!")
                    self.viewController.present(alert, animated: true, completion: nil)
                    return
                }
                
                self.send(attachment: (imageData, "image/png"))
            } else {
                let alert = UIAlertController.dismissable(title: "Error", message: "Could not publish message!")
                self.viewController.present(alert, animated: true, completion: nil)
            }
        }
    }
    
}


class DMConversationCellConfiguartor {
    
    func configure(_ cell: DMConversationSelfMessageCell, forDisplaying message: Message?, viewController: UIViewController) {
        
        cell.messageLabel.text = message?.body
        cell.didSelectLink = { link in
            UIApplication.shared.open(link, options: [.universalLinksOnly: true], completionHandler: { (success) in
                if !success {
                    // not a universal link or app not installed
                    let sfvc = SFSafariViewController(url: link)
                    viewController.present(sfvc, animated: true)
                }
            })
        }
    }
    
}
