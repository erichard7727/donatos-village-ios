//
//  NoticeAcknowledgementsViewController.swift
//  VillageContainerApp
//
//  Created by Justin Munger on 9/1/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

fileprivate typealias PeopleWrapper = [PersonWrapper]

fileprivate class PersonWrapper: NSObject {
    let person: Person
    
    init(_ person: Person) {
        self.person = person
    }
    
    @objc var firstName: String {
        return person.firstName ?? ""
    }
    
    @objc var lastName: String {
        return person.lastName ?? ""
    }
    
    @objc var displayName: String {
        return person.displayName ?? ""
    }
    
    @objc var jobTitle: String {
        return person.jobTitle ?? ""
    }
}

class NoticeAcknowledgementsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var progressIndicator: ProgressIndicator!
    
    let collation = UILocalizedIndexedCollation.current()
    var sections:  [People] = []
    var notice: Notice!
    
    var searchController: UISearchController!
    
    private var noticeAcknowledgements: PeopleWrapper = [] {
        didSet {
            sections = Array(repeating: [], count: collation.sectionTitles.count)
            
            let sortedObjects = collation.sortedArray(
                from: noticeAcknowledgements,
                collationStringSelector: #selector(getter: PersonWrapper.lastName)
            ) as! [PersonWrapper]
            
            for object in sortedObjects {
                let sectionNumber = collation.section(for: object, collationStringSelector: #selector(getter: PersonWrapper.lastName))
                sections[sectionNumber].append(object.person)
            }
            
            for index in 0 ... sections.count - 1 {
                let section = sections[index]
                sections[index] = section.sorted(by: { ($0.lastName ?? "") < ($1.lastName ?? "") })
            }
        }
    }
    
    private var originalAcknowledgements: PeopleWrapper = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 84.0
        
        // Setup search controller.
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        definesPresentationContext = true
        
        searchController.searchBar.searchBarStyle = .prominent
        searchController.searchBar.tintColor = UIColor(red: 233/255.0, green: 94/255.0, blue: 63/255.0, alpha: 1.0)
        
        self.progressIndicator = ProgressIndicator.progressIndicatorInView(self.view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let notice = self.notice else {
            return
        }
        
        progressIndicator.show()
        
        firstly {
            notice.getAcknowledgedList()
        }.then { [weak self] (people) in
            self?.noticeAcknowledgements.append(contentsOf: people.map(PersonWrapper.init))
            self?.originalAcknowledgements = self?.noticeAcknowledgements ?? []
        }.catch { [weak self] (error) in
            let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
            self?.present(alert, animated: true, completion: nil)
        }.always { [weak self] in
            self?.progressIndicator.hide()
            self?.tableView.reloadData()
        }
        
        searchController.searchBar.sizeToFit()
        tableView.tableHeaderView = searchController.searchBar
    }
    
    func predicateNotSelf() -> NSPredicate {
        return NSPredicate(format: "personId != %d", User.current.personId)
    }
    
}

extension NoticeAcknowledgementsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if sections[section].count == 0 {
            return nil
        } else {
            return collation.sectionTitles[section]
        }
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return collation.sectionIndexTitles
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        var sectionIndex = collation.section(forSectionIndexTitle: index)
        let totalSections = sections.count
        
        for counter in index ... totalSections - 1 {
            if sections[counter].count > 0 {
                sectionIndex = counter
                break
            }
        }
        
        return sectionIndex
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoticeAcknowledgementCell", for: indexPath) as! NoticeAcknowledgementCell

        let cellPerson = sections[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
        
        cell.nameLabel.text = cellPerson.displayName
        cell.titleLabel.text = cellPerson.jobTitle
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yy"
        if let acknowledgeDate = cellPerson.acknowledgeDate {
            cell.acknowledgedLabel.text = "Acknowledged " + formatter.string(from: acknowledgeDate)
        }
        
        cell.markAcknowledged(true)

        return cell
    }
}

extension NoticeAcknowledgementsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension NoticeAcknowledgementsViewController: UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchString = searchController.searchBar.text ?? ""
        let strippedSearchString = searchString.trimmingCharacters(in: CharacterSet.whitespaces)
        
        let words = strippedSearchString.components(separatedBy: " ")
        
        let predicates = words.map({ word -> NSPredicate in
            let subpredicates = [
                NSPredicate(format: "firstName CONTAINS[cd] %@", word),
                NSPredicate(format: "lastName CONTAINS[cd] %@", word),
                NSPredicate(format: "displayName CONTAINS[cd] %@", word),
                NSPredicate(format: "jobTitle CONTAINS[cd] %@", word)
            ]
            
            return NSCompoundPredicate(type: .or, subpredicates: subpredicates)
        })
        
        if strippedSearchString.count > 0 {
            let array = (originalAcknowledgements as NSArray).filtered(using: NSCompoundPredicate(type: .and, subpredicates: predicates))
            if let acknowledgementArray = array as? PeopleWrapper {
                noticeAcknowledgements = acknowledgementArray
            }
        } else {
            noticeAcknowledgements = originalAcknowledgements
        }
        
        tableView.reloadData()
    }
}
