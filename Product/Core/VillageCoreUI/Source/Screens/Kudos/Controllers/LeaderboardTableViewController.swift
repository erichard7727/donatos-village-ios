//
//  LeaderboardTableViewController.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 4/13/17.
//  Copyright © 2017 Dynamit. All rights reserved.
//

import UIKit
import AlamofireImage

class LeaderboardTableViewController: UIViewController, KudosServiceInjected {
    
    //Reuse people JSON parser from Notices in Other Models
    var list: [Persons]!
    var context: AppContext!
    var filter: FetchLeaderboardFilter!
    var currentPage: Int = 2
    var progressIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    var loadingMorePeople: Bool = false
    
    @IBOutlet weak var emptyStateLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let kudosNib = UINib(nibName: "LeaderboardCell", bundle: Constants.bundle)
        
        if list.count > 0 {
            emptyStateLabel.alpha = 0
        } else {
            emptyStateLabel.alpha = 1
        }
        emptyStateLabel.text = "Nobody is on the Leaderboard."
        
        tableView.register(kudosNib, forCellReuseIdentifier: "LeaderboardCell")
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 75.0
        
        tableView.alpha = 0
        UIView.animate(withDuration: 0.2, animations: {
            self.tableView.alpha = 1
        })
        
        displayProgressFooterView()
    }
    
    func displayProgressFooterView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 44))
        progressIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        progressIndicator.center = headerView.center
        headerView.addSubview(progressIndicator)
        progressIndicator.bringSubview(toFront: headerView)
        progressIndicator.startAnimating()
        progressIndicator.alpha = 0
        headerView.backgroundColor = UIColor.white
        tableView.tableFooterView = headerView
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -headerView.frame.height, right: 0)
    }
    
    func loadMorePeople() {
        self.loadingMorePeople = true
        
        kudosService.getLeaderboard(filter: filter, page: self.currentPage) {
            allResult in
            self.loadingMorePeople = false
            switch allResult {
            case .success(let allPeople):
                if let people = allPeople {
                    if people.count > 0 {
                        self.list.append(contentsOf: people)
                        self.currentPage = self.currentPage + 1
                        self.tableView.reloadSections([0], with: .automatic)
                    }
                }
            case .error(let error):
                var errorMessage: String
                if let localizedFailure = error.userInfo[NSLocalizedFailureReasonErrorKey] as? [String: AnyObject], let error = localizedFailure["error"] as? [String: AnyObject], let code = error["code"], let errorDescription = error["description"] as? String {
                    errorMessage = "E" + String(describing: code) + " - " + String(describing: errorDescription)
                } else {
                    errorMessage = "Could not update Leaderboard data."
                }
                let alert = UIAlertController.dismissableAlert("Error", message: errorMessage)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

extension LeaderboardTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LeaderboardCell", for: indexPath) as! LeaderboardCell
        cell.selectionStyle = .none
        
        let leaderBoardPerson = list[indexPath.row]
        
        if let points = leaderBoardPerson.points {
            cell.pointLabel.text = String(points)
        }
        cell.nameLabel.text = leaderBoardPerson.displayName
        cell.titleLabel.text = leaderBoardPerson.jobTitle
        cell.personID = String(leaderBoardPerson.id)
        
        
        if let url = URL(string: leaderBoardPerson.avatar.url) {
            let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                size: cell.avatarImageView.frame.size,
                radius: cell.avatarImageView.frame.size.height / 2
            )
            
            cell.avatarImageView.af_setImage(withURL: url, filter: filter)
        }
        
        cell.setCell()
        
        return cell
    }
}

extension LeaderboardTableViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.frame.size.height >= scrollView.contentSize.height {
            if !loadingMorePeople {
                progressIndicator.alpha = 1
                loadingMorePeople = true
                loadMorePeople()
            }
        }
    }
}
