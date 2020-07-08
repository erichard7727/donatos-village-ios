//
//  SelectPeopleViewController.swift
//  VillageCore
//
//  Created by Justin Munger on 5/3/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

protocol SelectPeopleViewControllerDelegate: class {
    func didSelectPeople(_ people: People)
}

class SelectPeopleViewController: UIViewController, NavBarDisplayable {
    
    @IBOutlet weak var completionBarButtonItem: UIBarButtonItem?
    @IBOutlet weak var searchTextView: UITextView!
    @IBOutlet weak var personSearchContainerView: UIView!
    @IBOutlet weak var giveKudosReasonContainerView: UIView!
    @IBOutlet weak var nextStepBarButtonItem: UIBarButtonItem!
    
    typealias Index = Int

    enum PeopleUpdate {
        case add(Person)
        case delete(Index)
    }
    
    weak var searchViewController: PersonSearchViewController!
    
    weak var delegate: SelectPeopleViewControllerDelegate?
    
    var searchText: String = ""
    var searchCurrentPage: Int = 1
    var groupMembers: People = []
    
    var peopleSelected: People = [] {
        didSet {
            if let completionBarButtonItem = self.completionBarButtonItem {
                completionBarButtonItem.isEnabled = peopleSelected.count > 0
            }
            
            if nextStepBarButtonItem != nil {
                nextStepBarButtonItem.isEnabled = peopleSelected.count > 0
            }
        }
    }
    
    var selectedPerson: Person? {
        didSet {
            let labels = peopleLabels
            for label in labels  {
                label.selected = false
            }
            
            if let person = selectedPerson, let index = peopleSelected.firstIndex(of: person) {
                labels[index].selected = true
            }
        }
    }
    
    var peopleLabels: [PersonLabel] = [] {
        didSet {
            redraw()
        }
    }
    
    @IBOutlet weak var emptyStateLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var limit: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .back)
        ])
        
        searchTextView.text = ""
        searchTextView.delegate = self
        
        activityIndicator.startAnimating()
        activityIndicator.alpha = 1
        
        emptyStateLabel.alpha = 0
        
        selectedPerson = .none
        
        if nextStepBarButtonItem != nil {
            nextStepBarButtonItem.isEnabled = false
        }
        
        clearSearch()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        searchViewController.searchAPI = nil
        searchViewController.stopAnimating = nil
        searchViewController.displayEmptyLabel = nil
        self.groupMembers = []
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavbarAppearance(for: navigationItem)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PersonSearch" {
            guard let searchViewController = segue.destination as? PersonSearchViewController else {
                fatalError("PersonSearchViewController not found")
            }
            
//            searchViewController.initialPredicates = initialPredicates
            searchViewController.delegate = self
            searchViewController.searchAPI = {
                self.searchAPI()
            }
            searchViewController.stopAnimating = {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.alpha = 0
            }
            searchViewController.displayEmptyLabel = {
                self.emptyStateLabel.text = "There are no people to display"
                self.emptyStateLabel.alpha = 1
            }
            searchViewController.groupMembers = self.groupMembers
            self.searchViewController = searchViewController
        }
    }
    
    @IBAction func completionButtonPressed(_ sender: UIBarButtonItem) {
        delegate?.didSelectPeople(peopleSelected)
    }
    
    func dismissModal() {
        delegate?.didSelectPeople(peopleSelected)
        if let navController = self.navigationController {
            navController.popViewController(animated: true)
        }
    }
    
    fileprivate func updatePeople(_ peopleUpdate: PeopleUpdate) {
        switch peopleUpdate {
        case .delete(let index):
            peopleLabels[index].view.removeFromSuperview()
            peopleLabels.remove(at: index)
            
            selectedPerson = .none
            peopleSelected.remove(at: index)
        case .add(let person):
            let label = PersonLabel(
                delegate: self,
                title: person.displayName ?? "",
                font: self.searchTextView.font
            )
            self.searchTextView.addSubview(label.view)
            peopleLabels.append(label)
            peopleSelected.append(person)
            if limit > 0 && peopleSelected.count == limit {
                dismissModal()
            }
        }
        self.clearSearch()
    }
    
    func clearSearch() {
        guard let searchViewController = self.searchViewController else {
            fatalError("SearchTableViewController not set")
        }
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchAPI), object: nil)

        searchViewController.peopleSelected = self.peopleSelected
        if searchViewController.inSearchMode {
            searchViewController.clearSearch()
            
            searchTextView.text = ""
            searchTextView.selectedRange = NSMakeRange(0, 0)
            searchViewController.inSearchMode = false
        }
    }
    
    
    func clickPersonLabel(_ label: PersonLabel) {
        if let index = peopleLabels.firstIndex(of: label) {
            selectedPerson = peopleSelected[index]
        }
    }
    
    func redraw() {
        if peopleLabels.count > 0 {
            let paddingX:   CGFloat = 5
            let startX:     CGFloat = 1
            var accumX:     CGFloat = startX
            var accumY:     CGFloat = 1
            var lineNumber: CGFloat = 0
            
            peopleLabels.forEach({
                /// Calculate x offset for line wrap.
                let endPos = accumX + $0.view.frame.width
                if endPos + 10 > self.searchTextView.frame.width {
                    lineNumber += 1
                    accumX = startX
                }
                accumY = ($0.view.frame.height / 2 - 1) + lineNumber * ($0.view.frame.height + paddingX)
                $0.view.frame.origin.x = accumX
                $0.view.frame.origin.y = accumY
                accumX += $0.view.frame.width + paddingX
            })
            
            /// Left indent.
            let indent = CGRect(x: 0, y: 0, width: accumX - startX, height: 1)
            searchTextView.textContainer.exclusionPaths = [UIBezierPath(rect: indent)]
            
            /// Top indent.
            searchTextView.textContainerInset.top = accumY
            searchTextView.setNeedsUpdateConstraints()
            searchTextView.updateConstraintsIfNeeded()
        } else {
            searchTextView.textContainer.exclusionPaths = [UIBezierPath(rect: CGRect(x: 0, y: 0, width: 0, height: 0))]
        }
    }
}

// MARK: UIViewControllerDelegate
extension SelectPeopleViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        searchViewController.inSearchMode = true
        searchCurrentPage = 1
        
        if textView.text.count == 0 {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchAPI), object: nil)
            activityIndicator.stopAnimating()
            activityIndicator.alpha = 0
            searchViewController.filteredpeople = Array(searchViewController.originalPeople)
            searchViewController.tableView.reloadData()
        }
        
        if let searchString = textView.text {
            searchText = searchString
            if searchString.trimmingCharacters(in: CharacterSet.whitespaces).count == 0 {
                self.searchViewController.filteredpeople = Array(self.searchViewController.originalPeople)
            } else {
                let strippedSearchString = searchString.trimmingCharacters(in: CharacterSet.whitespaces)
                
                self.searchViewController.filteredpeople = self.searchViewController.originalPeople.filter {
                    return $0.firstName?.lowercased().contains(strippedSearchString.lowercased()) ?? false
                        || $0.lastName?.lowercased().contains(strippedSearchString.lowercased()) ?? false
                        || $0.displayName?.lowercased().contains(strippedSearchString.lowercased()) ?? false
                        || $0.jobTitle?.lowercased().contains(strippedSearchString.lowercased()) ?? false
                }
            }
            self.searchViewController.sortPeopleList()
            
            self.searchViewController.tableView.reloadData()
    
            if textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count > 0 {
                self.searchText = textView.text
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchAPI), object: nil)
                self.perform(#selector(self.searchAPI), with: nil, afterDelay: 2)
                activityIndicator.alpha = 1
                activityIndicator.startAnimating()
                self.searchViewController.filteredpeople = []
                self.searchViewController.tableView.reloadData()
            }
        }
    }
    
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if let character = text.cString(using: String.Encoding.utf8) {
            let isBackspace = strcmp(character, "\\b")
            if isBackspace == -92 {
                backspacePressedInTextView(textView)
            }
        }
        if text == "\n" {
            return false
        }
        return true
    }
    
    @objc func searchAPI() {
        let trimmedQuery = self.searchText.trimmingCharacters(in: CharacterSet.newlines)
        searchViewController.loadingMorePeople = true
        
        firstly {
            People.search(for: trimmedQuery, page: searchCurrentPage)
        }.then { [weak self] people in
            guard let `self` = self else { return }
            
            if !people.isEmpty {
                self.searchCurrentPage = self.searchCurrentPage + 1
                for person in people {
                    if person.id != User.current.personId {
                        if !self.groupMembers.contains(person) {
                            self.searchViewController.originalPeople.insert(person)
                        }
                    }
                }
                self.searchViewController.filteredpeople = self.searchViewController.originalPeople.filter {
                    let id = $0.id
                    var returnValue = true
                    for person in self.peopleSelected {
                        if person.id == id {
                            returnValue = false
                        }
                    }

                    return (
                        $0.firstName?.lowercased().contains(trimmedQuery.lowercased()) ?? false
                            || $0.lastName?.lowercased().contains(trimmedQuery.lowercased()) ?? false
                            || $0.displayName?.lowercased().contains(trimmedQuery.lowercased()) ?? false
                            || $0.jobTitle?.lowercased().contains(trimmedQuery.lowercased()) ?? false
                    ) && returnValue
                }
                self.searchViewController.sortPeopleList()
            }
        }.catch { [weak self] error in
            let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
            self?.present(alert, animated: true, completion: nil)
        }.always {
            self.searchViewController.loadingMorePeople = false
            self.activityIndicator.stopAnimating()
            self.activityIndicator.alpha = 0
        }
    }
    
    func backspacePressedInTextView(_ textView: UITextView) {
        if textView.text.count < 1 &&
            peopleSelected.count > 0 {
            if let person = selectedPerson {
                let index = peopleSelected.firstIndex(of: person)
                self.updatePeople(.delete(index!))
                self.searchViewController.peopleSelected = self.peopleSelected
                self.searchViewController.clearSearch()
            } else {
                self.updatePeople(.delete(peopleSelected.count - 1))
                self.searchViewController.peopleSelected = self.peopleSelected
                self.searchViewController.clearSearch()
            }
            activityIndicator.stopAnimating()
            activityIndicator.alpha = 0
        } else if textView.text.count < 1 {
            activityIndicator.stopAnimating()
            activityIndicator.alpha = 0
        }
    }
}

extension SelectPeopleViewController: PersonSearchViewControllerDelegate {
    func personSelected(_ person: Person) {
        updatePeople(.add(person))
    }
}
