//
//  GroupSettingsController.swift
//  VillageCore
//
//  Created by Colin Drake on 3/1/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import Foundation
import UIKit
import VillageCore

protocol GroupSettingsControllerDelegate {
    func shouldLeaveGroup(_ group: VillageCore.Stream, controller: GroupSettingsController)
}

/// Group settings editor controller.
final class GroupSettingsController: UIViewController {
    // MARK: Properties
    
    var group: VillageCore.Stream?
    var delegate: GroupSettingsControllerDelegate?
    var progressIndicator: ProgressIndicator!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var leaveGroupButton: UIButton!
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .back)
        ])
        
        guard let group = self.group else {
            fatalError("group not set")
        }
        
        // Configure title.
        title = group.name + " Settings"
        
        if group.details?.streamType == .global {
            leaveGroupButton.isUserInteractionEnabled = false
            leaveGroupButton.setTitle("You can't leave a global group.", for: .normal)
            leaveGroupButton.setTitleColor(UIColor.vlgGray, for: .normal)
            leaveGroupButton.backgroundColor = UIColor.white
        }
        
        // Configure tableview.
        tableView.estimatedRowHeight = UITableView.automaticDimension
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.progressIndicator = ProgressIndicator.progressIndicatorInView(view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let group = self.group else {
            fatalError("group not set")
        }
        
        firstly {
            group.getDetails()
        }.then { [weak self] group in
            guard let `self` = self else { return }
            
            if self.group?.details?.streamType == .global {
                self.leaveGroupButton.isUserInteractionEnabled = false
                self.leaveGroupButton.setTitle("You can't leave a global group.", for: .normal)
                self.leaveGroupButton.setTitleColor(UIColor.gray, for: .normal)
                self.leaveGroupButton.backgroundColor = UIColor.vlgGray
            }
            self.group = group
            self.tableView.reloadData()
        }
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        if identifier == "GroupSettingsMembersSegue" {
            guard let vc = segue.destination as? MemberSelectionController else {
                fatalError("MemberSelectionController not found")
            }
            vc.group = group
        }
    }
    
    // MARK: Actions
    
    @IBAction func didTouchLeaveGroup(_ sender: UIButton) {
        guard let group = group else { return }
        
        let alert = UIAlertController(title: "Warning", message: "Are you sure you want to leave \(group.name)?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Leave Group", style: .destructive) { action in
            self.progressIndicator.show()
            
            firstly {
                group.unsubscribe()
            }.always { [weak self] in
                guard let `self` = self else { return }
                self.progressIndicator.hide()
                self.delegate?.shouldLeaveGroup(group, controller: self)
            }
        })

        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func didTouchCancel(_ sender: UIButton) {
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        }
    }
    
    @IBAction func didTouchSave(_ sender: UIButton) {
        let alert = UIAlertController.dismissable(title: "Error", message: "Not implemented yet!")
        present(alert, animated: true, completion: nil)
    }
    
}

// MARK: UITableViewDelegate

extension GroupSettingsController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let row = Rows.GeneralSettings(rawValue: indexPath.row) else {
            fatalError("Invalid row index")
        }
        
        switch row {
        case .name:
            // Editing name is not supported
            break
            
        case .type:
            guard String(User.current.personId) == group?.details?.ownerId else { return }
            
            let handler = { (action: UIAlertAction) in
                let newType: VillageCore.Stream.StreamType?
                
                switch action.title {
                case "Open":
                    newType = .open
                case "Open Invites":
                    newType = .memberInvites
                case "Closed":
                    newType = .closed
                default:
                    newType = nil
                }
                
                if let group = self.group, let newType = newType {
                    firstly {
                        group.edit(type: newType, name: nil, description: nil)
                    }.then { [weak self] _ in
                        self?.group?.details?.streamType = newType
                        self?.tableView.reloadData()
                    }.catch { [weak self] _ in
                        let alert = UIAlertController.dismissable(title: "Error", message: "The change to this group could not be saved.")
                        self?.present(alert, animated: true, completion: nil)
                    }
                }
            }
            
            let alert = UIAlertController(title: "Select a Group Type", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Open", style: .default, handler: handler))
            alert.addAction(UIAlertAction(title: "Open Invites", style: .default, handler: handler))
            alert.addAction(UIAlertAction(title: "Closed", style: .default, handler: handler))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            
        case .members:
            // This action is handled as a Storyboard Segue
            break
        }
    }
    
    internal func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return (section == 1 ? "Notifications Center" : nil)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView else { return }
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.white
        headerView.backgroundView = backgroundView
        headerView.textLabel?.font = UIFont(name: "ProximaNova-SemiBold", size: 20.0)
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
}

extension GroupSettingsController: UITableViewDataSource {
    struct Rows {
        enum GeneralSettings: Int, CaseIterable {
            case name
            case type
            case members
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Rows.GeneralSettings.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = Rows.GeneralSettings(rawValue: indexPath.row) else {
            fatalError("Invalid row index")
        }
        
        switch row {
        case .name:
            let cell = tableView.dequeueReusableCell(withIdentifier: "GroupSettingsNameCell") as! GroupSettingsNameCell
            cell.selectionStyle = .none
            cell.textField.text = group?.name
            return cell
            
        case .type:
            let cell = tableView.dequeueReusableCell(withIdentifier: "GroupSettingsTypeCell") as! GroupSettingsTypeCell
            cell.selectionStyle = .none
            cell.editButton.isHidden = String(User.current.personId) != group?.details?.ownerId
            cell.typeLabel.text = {
                switch group?.details?.streamType {
                case .open?:
                    return "Open"
                case .memberInvites?:
                    return "Member Invites"
                case .closed?:
                    return "Closed"
                case .global?:
                    return "Global"
                default:
                    return "Unknown"
                }
            }()
            return cell

        case .members:
            let cell = tableView.dequeueReusableCell(withIdentifier: "GroupSettingsMembersCell") as! GroupSettingsMembersCell
            cell.selectionStyle = .gray
            cell.countLabel.text = group?.details?.memberCount.description ?? nil
            return cell
        }
    }
}
