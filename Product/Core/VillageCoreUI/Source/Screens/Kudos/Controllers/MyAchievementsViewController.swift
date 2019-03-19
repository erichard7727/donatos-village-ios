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

class MyAchievementsViewController: UIViewController {

    var achievements: Achievements = []
    var index: Int?
    var personId: String?
    var otherUser: Person?
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cellNib = UINib(nibName: "AchievementCollectionViewCell", bundle: Constants.bundle)
        collectionView.register(cellNib, forCellWithReuseIdentifier: "AchievementCell")
        
        self.collectionView.contentInsetAdjustmentBehavior = .never
        
        #warning("TODO - Implement KudosService method here")
//        kudosService.getAchievements(personId: personId, canGiveKudos: nil) { result in
//            switch result {
//            case .success(let achievementsList):
//                AnalyticsHelper().logEvent(name: AnalyticsEventViewItemList, parameters: [AnalyticsParameterItemLocationID: "kudos" as NSObject, AnalyticsParameterItemCategory: "list" as NSObject, AnalyticsParameterItemName: "achievement list" as NSObject])
//                if let achievementArray = achievementsList, achievementArray.count > 0 {
//                    self.achievements = achievementArray
//                    self.collectionView.reloadSections([0])
//                }
//            case .error:
//                break
//            }
//        }
        
        collectionView.reloadData()
        collectionView.alpha = 1
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AchievementDetailsSegue" {
            #warning("TODO - Add in AchievementDetailsViewController")
            assertionFailure()
            
//            guard let vc = segue.destination as? AchievementDetailsViewController else { return }
//
//            if let i = index {
//
//                vc.achievement = achievements[i]
//
//                if let cell = collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as? AchievementCollectionViewCell {
//                    if let aIV = cell.achievementImageView {
//                        vc.achievementImage = aIV.imageView.image
//                    }
//                    if let pid = personId {
//                        vc.personId = Int(pid)
//                    } else {
//                        assertionFailure()
//                    }
//                }
//            }
//
//            if let otherReceiver = otherUser {
//                vc.otherUser = otherReceiver
//            }
        }
    }
    
    @IBAction func menuButtonPressed(_ sender: UIBarButtonItem) {
        sideMenuController?.showMenu()
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
        
        #warning("TODO - Configure achievement cell")
        
//        let achievement = achievements[indexPath.row]
        
//        cell.achievementTitleLabel.text = achievement.title
//        cell.achievementImageView?.progress = 0
//        cell.achievementImageView?.backgroundColor = UIColor.white
//        let badgeNumber = achievement.personPoints / achievement.pointsCap
//        cell.achievementImageView?.badgeNumber = Int(badgeNumber)
//
//        cell.achievementImageView?.progress = ((CGFloat(achievement.personPoints).truncatingRemainder(dividingBy: CGFloat(achievement.pointsCap))) / CGFloat(achievement.pointsCap)) as CGFloat
//        cell.points = Int(achievement.personPoints)
//        cell.pointsCap = Int(achievement.pointsCap)
//
//        if let attachmentJson = achievement.attachmentJSON, let url = URL(string: attachmentJson[0].url) {
//            if let aIV = cell.achievementImageView {
//                let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
//                    size: aIV.imageView.frame.size,
//                    radius: aIV.imageView.frame.size.height / 2
//                )
//                cell.activityIndicator.alpha = 1
//                cell.achievementImageView?.imageView.af_setImage(withURL: url, filter: filter, completion: { result in
//                    if achievement.personPoints/achievement.pointsCap < 1 {
//                        cell.achievementImageView?.imageView.alpha = 0.6
//                    } else {
//                        cell.achievementImageView?.imageView.alpha = 1.0
//                    }
//                    cell.activityIndicator.alpha = 0
//                    cell.activityIndicator.stopAnimating()
//                    cell.setNeedsLayout()
//                })
//            }
//        }
        return cell
    }
}
