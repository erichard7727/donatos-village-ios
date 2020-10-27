//
//  MyAchievementsViewController.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 9/15/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import VillageCore
import AlamofireImage
import Promises

class MyAchievementsViewController: UIViewController {

    var achievements: Achievements = []
    var index: Int?
    var person: Person?
    var otherUser: Person?
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            let cellNib = UINib(nibName: "AchievementCollectionViewCell", bundle: Constants.bundle)
            collectionView.register(cellNib, forCellWithReuseIdentifier: "AchievementCell")
            
            collectionView.contentInsetAdjustmentBehavior = .never
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)
        ])
        
        firstly { () -> Promise<Person> in
            if let person = self.person {
                return Promise(person)
            } else {
                return User.current.getPerson()
            }
        }.then { [weak self] person -> Promise<Achievements> in
            self?.person = person
            return person.achievements()
        }.then { [weak self] achievements in
            self?.achievements = achievements
            self?.collectionView.reloadSections([0])
            
            AnalyticsService.logEvent(name: AnalyticsEventViewItemList, parameters: [AnalyticsParameterItemLocationID: "kudos" as NSObject, AnalyticsParameterItemCategory: "list" as NSObject, AnalyticsParameterItemName: "achievement list" as NSObject])
        }.catch { [weak self] error in
            let alert = UIAlertController.dismissable(title: "Error", message: "There was a problem fetching achievements. Please try again.")
            self?.present(alert, animated: true, completion: nil)
        }
        
        collectionView.reloadData()
        collectionView.alpha = 1
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AchievementDetailsSegue" {
            guard let vc = segue.destination as? AchievementDetailsViewController else { return }

            if let i = index {

                vc.achievement = achievements[i]

                if let cell = collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as? AchievementCollectionViewCell {
                    if let aIV = cell.achievementImageView {
                        vc.achievementImage = aIV.imageView.image
                    }
                    vc.person = self.person
                }
            }

            if let otherReceiver = otherUser {
                vc.otherUser = otherReceiver
            }
        }
    }
    
}

extension MyAchievementsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        index = indexPath.row
        
        
        
        self.performSegue(withIdentifier: "AchievementDetailsSegue", sender: self)
    }
}

extension MyAchievementsViewController: UICollectionViewDataSource {
    private func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return achievements.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AchievementCell", for: indexPath) as! AchievementCollectionViewCell
        
        let achievement = achievements[indexPath.row]
        
        cell.achievementTitleLabel.text = achievement.title
        cell.achievementImageView?.progress = 0
        cell.achievementImageView?.backgroundColor = UIColor.white
        
        if achievement.pointsCap > 0 {
            let userPoints = achievement.userPoints ?? 0
            cell.achievementImageView?.badgeNumber = userPoints / achievement.pointsCap
            cell.achievementImageView?.progress = CGFloat(userPoints).truncatingRemainder(dividingBy: CGFloat(achievement.pointsCap)) / CGFloat(achievement.pointsCap)
        }
        
        cell.points = achievement.userPoints ?? 0
        cell.pointsCap = achievement.pointsCap
        
        if let imageView = cell.achievementImageView?.imageView,
           let url = achievement.mediaAttachments.first?.url {
            let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                size: imageView.frame.size,
                radius: imageView.frame.size.height / 2
            )
            cell.activityIndicator.alpha = 1
            imageView.vlg_setImage(withURL: url, filter: filter, completion: { result in
                if achievement.pointsCap > 0 && ((achievement.userPoints ?? 0) / achievement.pointsCap) < 1 {
                    cell.achievementImageView?.imageView.alpha = 0.6
                } else {
                    cell.achievementImageView?.imageView.alpha = 1.0
                }
                cell.activityIndicator.alpha = 0
                cell.activityIndicator.stopAnimating()
                cell.setNeedsLayout()
            })
        }
        
        return cell
    }
}
