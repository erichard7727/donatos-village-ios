//
//  MemberSelectionController.swift
//  VillageCore
//
//  Created by Colin Drake on 3/3/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import Foundation
import UIKit
import AlamofireImage
import VillageCore

// MARK: PeopleViewController
/// View controller for browsing and searching people.
final class MemberSelectionController: UITableViewController, NavBarDisplayable {
    // MARK: Properties
    
    /// Table view's data source.
//    var dataSource: DYTFetchedResultsDataSource!
    
    /// Searching controller.
    var searchController: UISearchController!
    
    /// Group to manage.
    var group: VillageCore.Stream!
        
    @IBOutlet weak var addMemberButton: UIBarButtonItem!
    
    var peopleList: [String: People] = [:]
    var tupleArray: [(key: String, value: People)] = []
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .back)
        ])
        
        let nib = UINib(nibName: "PersonCell", bundle: Constants.bundle)
        tableView.register(nib, forCellReuseIdentifier: "PersonCell")
        tableView.separatorStyle = .none
        
        if (group.details?.streamType == .closed && String(User.current.personId) != group.details?.ownerId)
            || self.group?.details?.streamType == .global {
            addMemberButton.isEnabled = false
            addMemberButton.tintColor = UIColor.clear
        }
        
        self.getStreamMemberShip()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        setNavbarAppearance(for: navigationItem)
    }
    
    func getStreamMemberShip() {
        self.peopleList = [:]
        self.tupleArray = []
        
        firstly {
            group.getMembers()
        }.then { [weak self] members in
            guard let `self` = self else { return }
            
            let groupedMembers = Dictionary(grouping: members, by: { member in
                String(member.firstName?.prefix(1) ?? "")
            })
                .flatMap({ (key, value) -> [String: People] in
                    return [key.uppercased() : value]
                })
            
            groupedMembers.forEach({ (prefix, people) in
                let mergedPeople = self.peopleList[prefix, default: []] + people
                self.peopleList[prefix] = mergedPeople
            })
                        
            self.tupleArray = self.peopleList
                .sorted { $0.0 < $1.0 }
            
            self.tableView.reloadData()
        }.catch { [weak self] _ in
            let alert = UIAlertController.dismissable(title: "Error", message: "Unable to fetch group members")
            self?.present(alert, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "InvitePeople" {
            guard let controller = segue.destination as? SelectPeopleViewController else {
                fatalError("SelectPeopleViewController not found")
            }
            
            guard let group = self.group else {
                fatalError("group not set")
            }
            
            controller.title = String(format: "Invite to %@", group.name)
            controller.delegate = self
            controller.groupMembers = tupleArray.flatMap({ $0.value })
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? PersonCell else {
            return
        }
        
        cell.initializeCell()
    }
}

extension MemberSelectionController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tupleArray.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionKey = tupleArray[section]
        return sectionKey.value.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonCell") as! PersonCell
        let array = tupleArray[indexPath.section].value
        let person = array[indexPath.row]
        cell.configureForPerson(person)
        
        if let url = person.avatarURL {
            let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                size: cell.avatarImageView.frame.size,
                radius: cell.avatarImageView.frame.size.height / 2
            )
            
            cell.avatarImageView.af_setImage(withURL: url, filter: filter)
        }
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 30))
        view.backgroundColor = UIColor.white
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "ProximaNova-SemiBold", size: 17.0)
        label.textColor = #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 0.9494881466)
        view.addSubview(label)
        
        let viewsDict = ["label": label]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[label]-|", options: [], metrics: nil, views: viewsDict))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[label]-20-|", options: [], metrics: nil, views: viewsDict))
        
        label.text = tupleArray[section].key.uppercased()
        
        return view
    }
}

extension MemberSelectionController: SelectPeopleViewControllerDelegate {
    func didSelectPeople(_ people: People) {
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        }
        
        let newView = UIView(frame: UIScreen.main.bounds)
        let frame = CGRect(x: view.bounds.origin.x, y: view.bounds.origin.y - 64, width: view.bounds.width, height: view.bounds.height)
        let progressIndicator: ProgressIndicator = ProgressIndicator.progressIndicatorWithFrame(frame, newView)
        self.tableView.addSubview(newView)
        progressIndicator.show()
        
        firstly {
            group.invite(people)
        }.then { [weak self] in
            let alert = UIAlertController(title: "Success", message: "Invitation has been sent.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { _ in
                self?.getStreamMemberShip()
            }))
            self?.present(alert, animated: true, completion: nil)
        }.catch {[weak self] error in
            let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
            self?.present(alert, animated: true, completion: nil)
        }.always {
            progressIndicator.hide()
        }
    }
}
