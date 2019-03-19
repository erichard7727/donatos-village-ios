//
//  AchievementDetailsViewController.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 9/20/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import AlamofireImage
import VillageCore

class AchievementDetailsViewController: UIViewController {
    
    var achievement: Achievement!
    var kudos: Kudos = []
    var achievementImage: UIImage!
    var currentPage: Int = 1
    var personId: Int?
    var otherUser: Person?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var kudosEmptyLabel: UILabel!
    
    let progressIndicator = UIActivityIndicatorView(style: .gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        kudosEmptyLabel.alpha = 0
        if let otherReceiver = otherUser {
            kudosEmptyLabel.text = otherReceiver.displayName
            kudosEmptyLabel.text?.append(" has not received any kudos for this achievement yet.")
        } else {
            kudosEmptyLabel.text = "You have not received any kudos for this achievement yet."
        }
        let kudosNib = UINib(nibName: "KudoCell", bundle: Constants.bundle)
        tableView.register(kudosNib, forCellReuseIdentifier: "KudoCell")
        
        let achievementNib = UINib(nibName: "AchievementHeaderCell", bundle: Constants.bundle)
        tableView.register(achievementNib, forCellReuseIdentifier: "AchievementHeaderCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 30
        displayProgressFooterView()
        
        automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getKudosForAchievement()
    }
    
    func getKudosForAchievement() {
        
        if let id = personId {
            kudosService.getKudos(filter: .received, currentPage: currentPage, achievementId: achievement.achievementId, personId: id) { result in
                self.progressIndicator.alpha = 0
                switch result {
                case .success(let kudosList):
                    if let list = kudosList , list.count > 0 {
                        self.currentPage = self.currentPage + 1
                        self.kudos = list
                        self.tableView.reloadSections([1], with: .automatic)
                    } else if kudosList?.count == 0 {
                        self.kudosEmptyLabel.alpha = 1
                    }
                case .error(let error):
                    var errorMessage: String
                    if let localizedFailure = error.userInfo[NSLocalizedFailureReasonErrorKey] as? [String: AnyObject], let error = localizedFailure["error"] as? [String: AnyObject], let code = error["code"], let errorDescription = error["description"] as? String {
                        errorMessage = "E" + String(describing: code) + " - " + String(describing: errorDescription)
                    } else {
                        errorMessage = "Could not update Achievement data."
                    }
                    let alert = UIAlertController.dismissableAlert("Error", message: errorMessage)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction override func backButtonPressed(_ sender: UIBarButtonItem) {
        if let navController = navigationController {
            navController.popViewController(animated: true)
        }
    }
    
    func displayProgressFooterView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: (self.tableView?.frame.width)!, height: 44))
        progressIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        progressIndicator.center = headerView.center
        headerView.addSubview(progressIndicator)
        progressIndicator.bringSubview(toFront: headerView)
        progressIndicator.startAnimating()
        progressIndicator.alpha = 1
        headerView.backgroundColor = UIColor.white
        tableView.tableFooterView = headerView
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -headerView.frame.height, right: 0)
    }
}

extension AchievementDetailsViewController: UITableViewDelegate {
    
}

extension AchievementDetailsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            if kudos != nil {
                return kudos.count
            } else {
                return 0
            }
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementHeaderCell") as! AchievementHeaderCell
            
            cell.achievementTitle.text = achievement.title
            
            let remainder = CGFloat(achievement.personPoints).truncatingRemainder(dividingBy: CGFloat(achievement.pointsCap))
            let remainderPercentage = remainder/CGFloat(achievement.pointsCap) as CGFloat
            cell.achievementImageView.progress = remainderPercentage
            cell.pointsLabel.text = "\(Int(remainder))/\(Int(achievement.pointsCap))"
            cell.points = Int(achievement.personPoints)
            cell.pointsCap = Int(achievement.pointsCap)
            
            cell.achievementImageView.badgeNumber = Int(achievement.personPoints / achievement.pointsCap)
            
            
            if let image = achievementImage {
                cell.achievementImageView.imageView.image = image
                cell.achievementImageView.imageView.alpha = 1.0
                if let points = cell.points, let cap = cell.pointsCap, points/cap < 1 {
                    cell.achievementImageView.imageView.alpha = 0.6
                } else {
                    cell.achievementImageView.imageView.alpha = 1.0
                }
            } else {
                if let attachmentJson = achievement.attachmentJSON, let url = URL(string: attachmentJson[0].url) {
                    let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                        size: cell.achievementImageView.imageView.frame.size,
                        radius: cell.achievementImageView.imageView.frame.size.height / 2
                    )
                    cell.achievementImageView.imageView.af_setImage(withURL: url, filter: filter, completion: { result in
                        if self.achievement.personPoints/self.achievement.pointsCap < 1 {
                            cell.achievementImageView.imageView.alpha = 0.6
                        } else {
                            cell.achievementImageView.imageView.alpha = 1.0
                        }
                    })
                    cell.achievementImageView.imageView.alpha = 1.0
                }
            }
            
            cell.descriptionLabel.text = achievement.achievementDescription
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "KudoCell") as! KudoCell
            cell.displayDateLabel = true
            
            let kudo = kudos[indexPath.row]
            let achievementString = "for " + kudo.achievementTitle
            
            let regAttributes = [NSFontAttributeName: UIFont(name: "ProximaNova-Regular", size: 15.0)!]
            let boldAttributes = [NSFontAttributeName: UIFont(name: "ProximaNova-SemiBold", size: 15.0)!]
            
            let sender = NSAttributedString(string: kudo.sender.displayName, attributes: boldAttributes)
            
            let title = NSMutableAttributedString()
            title.append(sender)
            
            if let otherReceiver = otherUser {
                let receiver = NSAttributedString(string: otherReceiver.displayName, attributes: boldAttributes)
                
                title.append(NSAttributedString(string: " gave ", attributes: regAttributes))
                title.append(receiver)
                title.append(NSAttributedString(string:  " kudos for \(kudo.achievementTitle)", attributes: regAttributes))
            } else {
                title.append(NSAttributedString(string: " gave you kudos \(achievementString)", attributes: regAttributes))
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd"
            var dateString = ""
            if let date = kudo.created {
                dateString = formatter.string(from: date as Date)
            }
            
            cell.configure(
                title: title,
                comment: kudo.comment,
                points: kudo.points,
                date: dateString
            )
            
            if let url = URL(string: kudo.sender.avatar.url), let avatarImageView = cell.avatarImageView {
                let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                    size: avatarImageView.frame.size,
                    radius: avatarImageView.frame.size.height / 2
                )
                
                cell.avatarImageView?.af_setImage(withURL: url, filter: filter)
            }
            
            return cell
        }
    }
}
