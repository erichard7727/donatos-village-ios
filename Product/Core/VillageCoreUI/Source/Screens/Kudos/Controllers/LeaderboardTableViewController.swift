//
//  LeaderboardTableViewController.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 4/13/17.
//  Copyright © 2017 Dynamit. All rights reserved.
//

import UIKit
import AlamofireImage
import VillageCore
import Promises

class LeaderboardTableViewController: UIViewController {
    
    enum Filter {
        case week
        case all
        
        fileprivate func leaderboard(page: Int) -> Promise<People> {
            switch self {
            case .week:
                return Kudos.weeklyLeaderboard(page: page)
            case .all:
                return Kudos.leaderboard(page: page)
            }
        }
    }
    
    static func make(for filter: Filter) -> LeaderboardTableViewController {
        let storyboard = UIStoryboard(name: "Kudos", bundle: Constants.bundle)
        let vc = storyboard.instantiateViewController(withIdentifier: "LeaderboardTableViewController") as! LeaderboardTableViewController
        vc.filter = filter
        return vc
    }
    
    //Reuse people JSON parser from Notices in Other Models
    private var list: People = []
    private var filter: Filter!
    private var currentPage: Int = 1
    
    private lazy var progressIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .gray)
        view.hidesWhenStopped = true
        return view
    }()
    
    private var loadingMorePeople: Bool = false
    
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var emptyStateLabel: UILabel! {
        didSet {
            emptyStateLabel.text = "Nobody is on the Leaderboard."
            emptyStateLabel.isHidden = true
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let kudosNib = UINib(nibName: "LeaderboardCell", bundle: Constants.bundle)
        
        tableView.register(kudosNib, forCellReuseIdentifier: "LeaderboardCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 75.0
        
        tableView.alpha = 0
        UIView.animate(withDuration: 0.2, animations: {
            self.tableView.alpha = 1
        })
        
        displayProgressFooterView()
        
        self.loadingIndicator.startAnimating()
        loadMorePeople { [weak self] in
            self?.loadingIndicator.stopAnimating()
        }
    }
    
    func displayProgressFooterView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 44))
        progressIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        progressIndicator.center = headerView.center
        headerView.addSubview(progressIndicator)
        progressIndicator.bringSubviewToFront(headerView)
        headerView.backgroundColor = UIColor.white
        tableView.tableFooterView = headerView
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -headerView.frame.height, right: 0)
    }
    
    func loadMorePeople(completion: @escaping () -> Void) {
        self.loadingMorePeople = true
        
        firstly {
            self.filter.leaderboard(page: self.currentPage)
        }.then { [weak self] people in
            guard let `self` = self else { return }
            
            self.list.append(contentsOf: people)
            self.tableView.reloadSections([0], with: .automatic)
            
            if !people.isEmpty {
                self.currentPage = self.currentPage + 1
            }
            
            self.emptyStateLabel.isHidden = !self.list.isEmpty
        }.catch { [weak self] error in
            let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
            self?.present(alert, animated: true, completion: nil)
        }.always { [weak self] in
            self?.loadingMorePeople = false
            completion()
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
        
        if leaderBoardPerson.kudos.points > 0 {
            cell.pointLabel.text = leaderBoardPerson.kudos.points.description
        }
        cell.nameLabel.text = leaderBoardPerson.displayName
        cell.titleLabel.text = leaderBoardPerson.jobTitle
        cell.personID = String(leaderBoardPerson.id)
        
        
        if let url = leaderBoardPerson.avatarURL {
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
                progressIndicator.startAnimating()
                loadMorePeople { [weak self] in
                    self?.progressIndicator.stopAnimating()
                }
            }
        }
    }
}
