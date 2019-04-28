//
//  MediaPreviewViewController.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 2/22/17.
//  Copyright © 2017 Dynamit. All rights reserved.
//

import UIKit
import SafariServices
import Alamofire
import AlamofireImage
import VillageCore

class MediaPreviewViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
    
    var navHeight: CGFloat!
    var message: Message!
    var isDirectMessage: Bool = false
    var image: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableViewTopConstraint.constant = navHeight
        
        self.tableView.backgroundColor = UIColor(white: 0, alpha: 0.7)
        view.backgroundColor = UIColor(white: 0, alpha: 0.7)
        view.isOpaque = false
        
        let nib = UINib(nibName: "GroupMessageCell", bundle: Constants.bundle)
        tableView.register(nib, forCellReuseIdentifier: "GroupMessageCell")
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func saveImage() {
        if let attachmentImage = image {
            if let pngRepresentation = attachmentImage.pngData(),
                let data = UIImage(data: pngRepresentation) {
                UIImageWriteToSavedPhotosAlbum(data, nil, nil, nil)
                
                let alert = UIAlertController.dismissable(title: "Success", message: "Image saved to album")
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertController.dismissable(title: "Error", message: "Could not save image")
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension MediaPreviewViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GroupMessageCell") as! GroupMessageCell
            
            cell.isDirectMessage = isDirectMessage
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
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PreviewImageCell") as! PreviewImageCell
            cell.selectionStyle = .none
            
            cell.backgroundColor = UIColor.clear
            
            if let attachment = message.attachment {
                if attachment.type == "image/gif" {
                    Alamofire.request(attachment.url, method: .get).responseImage { response in
                            guard let image = response.data else {
                                return
                            }
                            
                            if let attachmentImage = UIImage(animatedImageData: image as Data) {
                                cell.configureCellAnimatedAttachment(attachmentImage)
                            }
                    }
                } else {
                    cell.configureCellAttachment(image, "")
                }
            }

            cell.longTap = {
                let alert = UIAlertController(title: "Save", message: "Save image to library?", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) in
                    self.saveImage()
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
                    alert.dismiss(animated: true, completion: nil)
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
            
            return cell
        } else if indexPath.row  == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PreviewActionCell") as! PreviewActionCell
            cell.backgroundColor = UIColor.clear
            cell.actionLabel.text = "Reply in Stream"
            
            return cell
        } else if indexPath.row == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PreviewActionCell") as! PreviewActionCell
            cell.backgroundColor = UIColor.clear
            
            cell.iconImageView.tintColor = UIColor.white
            cell.iconImageView.image = UIImage.named("menu-direct-messages")
            cell.actionLabel.text = "Send Private Reply"
            
            return cell
        } else {
            let cell = UITableViewCell()
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 91
        } else if indexPath.row == 1 {
            return 350
        } else if indexPath.row  == 2 {
            return 50
        } else if indexPath.row == 3 {
            return 50
        } else {
            return 0
        }
    }
}

extension MediaPreviewViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
