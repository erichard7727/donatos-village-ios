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
    var person: Person?
    var otherUser: Person?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var kudosEmptyLabel: UILabel!
    
    lazy var progressIndicator: UIActivityIndicatorView =  {
        let view = UIActivityIndicatorView(style: .gray)
        view.hidesWhenStopped = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)
        ])
        
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
        
        tableView.contentInsetAdjustmentBehavior = .never
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.currentPage == 1 {
            getKudosForAchievement()
        }
    }
    
    func getKudosForAchievement() {
        guard let person = self.person else { return }
        
        progressIndicator.startAnimating()
        
        firstly {
            person.kudosReceived(achievement: achievement, page: currentPage)
        }.then { [weak self] kudos in
            guard let `self` = self else { return }
            self.currentPage = self.currentPage + 1
            self.kudos = kudos
            self.tableView.reloadSections([1], with: .automatic)
            self.kudosEmptyLabel.isHidden = !kudos.isEmpty
        }.catch { [weak self] error in
            let errorMessage = (error as? VillageServiceError)?.userDisplayableMessage ?? VillageServiceError.genericFailureMessage
            let alert = UIAlertController.dismissable(title: "Error", message: errorMessage)
            self?.present(alert, animated: true, completion: nil)
        }.always { [weak self] in
            self?.progressIndicator.stopAnimating()
        }
    }
    
    func displayProgressFooterView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: (self.tableView?.frame.width)!, height: 44))
        progressIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        progressIndicator.center = headerView.center
        headerView.addSubview(progressIndicator)
        progressIndicator.bringSubviewToFront(headerView)
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
            return kudos.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementHeaderCell") as! AchievementHeaderCell
            
            cell.achievementTitle.text = achievement.title
            
            let remainder = CGFloat(achievement.userPoints ?? 0).truncatingRemainder(dividingBy: CGFloat(achievement.pointsCap))
            let remainderPercentage = remainder/CGFloat(achievement.pointsCap) as CGFloat
            cell.achievementImageView.progress = remainderPercentage
            cell.pointsLabel.text = "\(Int(remainder))/\(Int(achievement.pointsCap))"
            cell.points = Int(achievement.userPoints ?? 0)
            cell.pointsCap = Int(achievement.pointsCap)
            
            cell.achievementImageView.badgeNumber = Int((achievement.userPoints ?? 0) / achievement.pointsCap)
            
            
            if let image = achievementImage {
                cell.achievementImageView.imageView.image = image
                cell.achievementImageView.imageView.alpha = 1.0
                if let points = cell.points, let cap = cell.pointsCap, points/cap < 1 {
                    cell.achievementImageView.imageView.alpha = 0.6
                } else {
                    cell.achievementImageView.imageView.alpha = 1.0
                }
            } else {
                if let url = achievement.mediaAttachments.first?.url {
                    let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                        size: cell.achievementImageView.imageView.frame.size,
                        radius: cell.achievementImageView.imageView.frame.size.height / 2
                    )
                    cell.achievementImageView.imageView.af_setImage(withURL: url, filter: filter, completion: { result in
                        if (self.achievement.userPoints ?? 0) / self.achievement.pointsCap < 1 {
                            cell.achievementImageView.imageView.alpha = 0.6
                        } else {
                            cell.achievementImageView.imageView.alpha = 1.0
                        }
                    })
                    cell.achievementImageView.imageView.alpha = 1.0
                }
            }
            
            cell.descriptionLabel.text = achievement.description
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "KudoCell") as! KudoCell
            cell.displayDateLabel = true
            
            let kudo = kudos[indexPath.row]
            let achievementString = "for " + kudo.achievementTitle
            
            let regAttributes = [NSAttributedString.Key.font: UIFont(name: "ProximaNova-Regular", size: 15.0)!]
            let boldAttributes = [NSAttributedString.Key.font: UIFont(name: "ProximaNova-SemiBold", size: 15.0)!]
            
            let sender = NSAttributedString(string: kudo.sender.displayName ?? "", attributes: boldAttributes)
            
            let title = NSMutableAttributedString()
            title.append(sender)
            
            if let otherReceiver = otherUser {
                let receiver = NSAttributedString(string: otherReceiver.displayName ?? "", attributes: boldAttributes)
                
                title.append(NSAttributedString(string: " gave ", attributes: regAttributes))
                title.append(receiver)
                title.append(NSAttributedString(string:  " kudos for \(kudo.achievementTitle)", attributes: regAttributes))
            } else {
                title.append(NSAttributedString(string: " gave you kudos \(achievementString)", attributes: regAttributes))
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd"
            
            cell.configure(
                title: title,
                comment: kudo.comment,
                points: kudo.points,
                date: formatter.string(from: kudo.date),
                didSelectAvatar: { [weak self] in
                    let vc = UIStoryboard(name: "Directory", bundle: Constants.bundle).instantiateViewController(withIdentifier: "PersonProfileViewController") as! PersonProfileViewController
                    vc.person = kudo.receiver
                    vc.delegate = self
                    self?.show(vc, sender: self)
                },
                showMoreOptions: {
                    assertionFailure("Showing more options has not been implemented!")
                }
            )

            if let url = kudo.sender.avatarURL, let avatarImageView = cell.avatarImageView {
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

// MARK: - PersonProfileViewControllerDelegate

extension AchievementDetailsViewController: PersonProfileViewControllerDelegate {

    func shouldShowAndStartDirectMessage(_ directMessage: VillageCore.Stream, controller: ContactPersonViewController) {
        let dataSource = DirectMessageStreamDataSource(stream: directMessage)
        let vc = StreamViewController(dataSource: dataSource)
        self.sideMenuController?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
    }

}
