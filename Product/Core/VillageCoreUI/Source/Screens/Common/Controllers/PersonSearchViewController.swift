//
//  PersonSearchViewController.swift
//  VillageCore
//
//  Created by Justin Munger on 5/3/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import AlamofireImage
import VillageCore

protocol PersonSearchViewControllerDelegate: class {
    func personSelected(_ person: Person)
}

class PersonSearchViewController: UITableViewController {

    weak var delegate: PersonSearchViewControllerDelegate?
    
    var filteredpeople: People = []
    var originalPeople = Set<Person>()
    var selectedPeople: People = []
    var currentPage: Int = 1
    var loadingMorePeople: Bool = false
    
    var groupMembers: People = []
    
    let progressIndicator = UIActivityIndicatorView(style: .gray)
    
    var peopleSelected: People = []
    var searchAPI: (() -> ())?
    var stopAnimating: (() -> ())?
    var displayEmptyLabel: (() -> ())?
    var inSearchMode: Bool = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 90.0
        
        let nib = UINib(nibName: "PersonCell", bundle: Constants.bundle)
        tableView.register(nib, forCellReuseIdentifier: "PersonCell")
        
        getPeople()
    }
    
    func getPeople() {
        loadingMorePeople = true
        
        firstly {
            People.getDirectory(page: self.currentPage)
        }.then { [weak self] people in
            guard let `self` = self else { return }
            
            if !people.isEmpty {
                self.currentPage = self.currentPage + 1
                for person in people {
                    if person.id != User.current.personId {
                        if !self.groupMembers.contains(person) {
                            self.originalPeople.insert(person)
                        }
                    }
                }
                self.filteredpeople = Array(self.originalPeople)
                self.sortPeopleList()
            }
            
            if self.filteredpeople.isEmpty {
                self.displayEmptyLabel?()
            }
        }.catch { [weak self] error in
            let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
            self?.present(alert, animated: true, completion: nil)
        }.always { [weak self] in
            self?.refreshControl?.endRefreshing()
            self?.loadingMorePeople = false
            self?.stopAnimating!()
        }
    }
    
    func predicateFirstName(_ s: String) -> NSPredicate {
        return NSPredicate(format: "firstName CONTAINS[cd] %@", s)
    }
    func predicateLastName(_ s: String) -> NSPredicate {
        return NSPredicate(format: "lastName CONTAINS[cd] %@", s)
    }
    
    func predicateNotSelf() -> NSPredicate {
        return NSPredicate(format: "personId != %d", User.current.personId)
    }
    
    func predicateNotPeopleSelected(personId: Int) -> NSPredicate {
        return NSPredicate(format: "personId != %d", personId)
    }
    
    
    func clearSearch() {
        self.filteredpeople = Array(originalPeople).filter {
            let id = $0.id
            var returnValue = true
            for person in peopleSelected {
                if person.id == id {
                    returnValue = false
                }
            }
            return returnValue
        }
    
        sortPeopleList()
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cellPerson = filteredpeople[indexPath.row]
        filteredpeople.remove(at: indexPath.row)
        tableView.reloadData()
        delegate?.personSelected(cellPerson)
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? PersonCell else {
            return
        }
        
        cell.initializeCell()
    }
}

extension PersonSearchViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredpeople.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonCell") as! PersonCell
        
        let person = filteredpeople[indexPath.row]
        cell.configureForPerson(person)
        
        if let url = person.avatarURL {
            let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                size: cell.avatarImageView.frame.size,
                radius: cell.avatarImageView.frame.size.height / 2
            )
            
            cell.avatarImageView.vlg_setImage(withURL: url, filter: filter)
        }
        
        return cell
    }
    
    func displayProgressFooterView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 44))
        progressIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        progressIndicator.center = headerView.center
        headerView.addSubview(progressIndicator)
        progressIndicator.bringSubviewToFront(headerView)
        progressIndicator.startAnimating()
        progressIndicator.alpha = 0
        headerView.backgroundColor = UIColor.white
        tableView.tableFooterView = headerView
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -headerView.frame.height, right: 0)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.frame.size.height + 30 >= scrollView.contentSize.height {
            if !loadingMorePeople {
                if inSearchMode {
                    self.searchAPI?()
                } else {
                    progressIndicator.alpha = 1
                    loadMorePeople()
                }
            }
        }
    }
    
    func loadMorePeople() {
        // Don't refresh data if we're in search mode.
        loadingMorePeople = true
        
        firstly {
            People.getDirectory(page: self.currentPage)
        }.then { [weak self] people in
            guard let `self` = self else { return }
            
            if !people.isEmpty {
                self.currentPage = self.currentPage + 1
                for person in people {
                    if person.id != User.current.personId {
                        if !self.groupMembers.contains(person) {
                            self.originalPeople.insert(person)
                        }
                    }
                }
                self.filteredpeople = Array(self.originalPeople)
                self.sortPeopleList()
            }
            
            if self.filteredpeople.isEmpty {
                self.displayEmptyLabel?()
            }
        }.catch { [weak self] error in
            let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
            self?.present(alert, animated: true, completion: nil)
        }.always { [weak self] in
            self?.loadingMorePeople = false
        }
    }
    
    func sortPeopleList() {
        
        let newPeopleList: People = filteredpeople.sorted(by: { (lhs, rhs) -> Bool in
            if let lLastname = lhs.lastName?.lowercased(), let rLastname = rhs.lastName?.lowercased() {
                return lLastname < rLastname
            } else if let lFirstname = lhs.firstName?.lowercased(), let rFirstname = rhs.firstName?.lowercased() {
                return lFirstname < rFirstname
            } else {
                return false
            }
        })
        
        filteredpeople = newPeopleList
        tableView.reloadData()
    }
}
