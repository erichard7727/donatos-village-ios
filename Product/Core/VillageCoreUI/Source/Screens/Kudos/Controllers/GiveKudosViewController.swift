//
//  GiveKudosViewController.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 9/12/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import DynamitCoreDataKit

class GiveKudosViewController: UIViewController, KeyboardExpandable, KudosServiceInjected {
    
    var context: AppContext!
    
    lazy var pickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        return pickerView
    }()
    
    lazy var progressIndicator: ProgressIndicator = {
        return ProgressIndicator.progressIndicatorInView(self.view)
    }()
    
    @IBOutlet fileprivate weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView?
    
    @IBOutlet fileprivate weak var recipientTextView: UITextView! {
        didSet {
            recipientTextView.isScrollEnabled = false
            recipientTextView.text = nil
        }
    }
    
    @IBOutlet fileprivate weak var categoryTextField: IndentedTextField! {
        didSet {
            categoryTextField.inputView = pickerView
        }
    }
    
    @IBOutlet fileprivate weak var reasonTextView: UITextView! {
        didSet {
            reasonTextView.text = nil
            reasonTextView.addSubview(placeholderText)
            placeholderText.frame.origin = CGPoint(x: 5, y: (reasonTextView.font?.pointSize)! / 2)
        }
    }
    
    @IBOutlet fileprivate weak var submitButton: UIButton!
    
    internal var keyboardObservers: [NSObjectProtocol]?
    
    // Placeholder text label for textView
    fileprivate lazy var placeholderText: UILabel = {
        let placeholderText = UILabel()
        placeholderText.text = "Tell them why..."
        placeholderText.font = self.reasonTextView.font
        placeholderText.sizeToFit()
        placeholderText.textColor = UIColor(white: 0, alpha: 0.3)
        return placeholderText
    }()
    
    fileprivate lazy var inputAccessory: UIToolbar = {
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50))
        toolBar.barStyle = UIBarStyle.default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(done))
        toolBar.items = [flexSpace, doneButton]
        toolBar.sizeToFit()
        return toolBar
    }()
    
    fileprivate var selectPeopleVC: SelectPeopleViewController {
        let storyboard = UIStoryboard(name: "Kudos", bundle: .main)
        let vc = storyboard.instantiateViewController(withIdentifier: "SelectPeopleViewController") as! SelectPeopleViewController
        vc.context = self.context
        vc.groupMembers = []
        vc.delegate = self
        vc.limit = 1
        return vc
    }
    
    fileprivate var achievements: [Achievementss]!
    
    fileprivate var selectedPerson: Persons? {
        didSet {
            recipientTextView.text = selectedPerson?.displayName
        }
    }
    
    fileprivate var selectedAchievementIndex: Int? {
        didSet {
            guard let selectedAchievementIndex = selectedAchievementIndex,
                  selectedAchievementIndex < achievements.count else {
                categoryTextField.text = nil
                return
            }
            categoryTextField.text = achievements[selectedAchievementIndex].title
        }
    }
    
    // The points are always 1 at this point and cannot be changed in the UI
    fileprivate var selectedPoints = 1
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            AccommodatesKeyboardBehavior(),
        ])
        
        categoryTextField.inputAccessoryView = inputAccessory
        reasonTextView.inputAccessoryView = inputAccessory
        
//        context.fetchAchievements(personId: nil, canUserGiveKudos: true) { result in
//            switch result {
//            case .success(let achievementList):
//                if let achievements = achievementList {
//                    self.achievements = achievements
//                    self.pickerView.reloadAllComponents()
//                }
//                break
//            case .error(let error):
//                print(error)
//            }
//            
//        }
        
        kudosService.getAchievements(personId: nil, canGiveKudos: true) {
            result in
            switch result {
            case .success(let achievementList):
                if let achievements = achievementList {
                    self.achievements = achievements
                    self.pickerView.reloadAllComponents()
                }
                break
            case .error(let error):
                print(error)
            }
        }
        
        resetForm()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Target/Action
    
    @IBAction func giveKudoPressed(_ sender: UIButton) {
        guard validateForm() else { return }
        
        guard let comment = reasonTextView.text,
              let receiverName = selectedPerson?.displayName,
              let receiverId = selectedPerson?.id else {
            assertionFailure("Missing required values. Is validateForm() up-to-date?")
            return
        }
        
        self.progressIndicator.show()
        
        kudosService.giveKudosService(
            achievementId: achievements[selectedAchievementIndex!].achievementId,
            comment: comment,
            points: 1,
            receiverId: receiverId) {
                result in
                self.progressIndicator.hide()
                
                switch result {
                case .success(_):
                    let alert = UIAlertController(
                        title: "Success",
                        message: "Your kudos to \(receiverName) has been sent.",
                        preferredStyle: .alert
                    )
                    let giveAnother = UIAlertAction(title: "Give Another", style: .default, handler: {
                        _ in
                        self.resetForm()
                    })
                    alert.addAction(giveAnother)
                    
                    let myKudos = UIAlertAction(title: "My Kudos", style: .default, handler: {
                        _ in
                        self.transitionToMyKudos()
                    })
                    alert.addAction(myKudos)
                    
                    self.present(alert, animated: true, completion: nil)
                    
                case .error(let error):
                    
                    let alert = UIAlertController(
                        title: "Error",
                        message: "E" + error.code.description + " - " + error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
        }
        
    }
    
    fileprivate func transitionToMyKudos() {
        if let menuController = self.sideMenuController {
            let controller = UIStoryboard(name: "Kudos", bundle: Constants.bundle).instantiateViewController(withIdentifier: "MyKudosViewController") as! MyKudosViewController
            controller.context = self.context
            controller.selectedFilter = MyKudosViewController.filter.given
            let nav = VillageNavigationController(rootViewController: controller)
            menuController.swapOutCenterViewController(nav, animated: true)
        }
    }
    
    @IBAction func menuItemPressed(_ sender: UIBarButtonItem!) {
        guard let sideMenuController = sideMenuController else {
            return
        }
        sideMenuController.showLeftMenuController(true)
    }

    // MARK: - 
    
    internal func done() {
        view.endEditing(true)
    }
    
    fileprivate func resetForm() {
        selectedPerson = nil
        reasonTextView.text = nil
        placeholderText.isHidden = false
        selectedAchievementIndex = nil
        selectedPoints = 1
    }
    
    /// Performs form validation, presenting an error alert if not.
    ///
    /// - Returns: True if the form is valid, false if not
    fileprivate func validateForm() -> Bool {
        
        var fieldErrors: [String] = []
        
        if self.selectedPerson == nil {
            fieldErrors += ["A recipient is required."]
        }
        
        if self.selectedAchievementIndex == nil {
            fieldErrors += ["A category is required."]
        }
        
        if self.reasonTextView.text.isEmpty {
            fieldErrors += ["A reason is required."]
        }
        
        if !fieldErrors.isEmpty {
            let alert = UIAlertController(
                title: "Missing Required \(fieldErrors.count == 1 ? "Field" : "Fields")",
                message: fieldErrors.joined(separator: " "),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        return fieldErrors.isEmpty
    }
}

// MARK: - UITextViewDelegate

extension GiveKudosViewController: UITextViewDelegate {
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView == recipientTextView {
            if let navController = navigationController {
                navController.pushViewController(self.selectPeopleVC, animated: true)
            }
            return false
        }
        
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Grab text, etc.
        let string = textView.text ?? ""
        let newValue = NSString(string: string).replacingCharacters(in: range, with: text)
        
        if textView == reasonTextView {
            placeholderText.isHidden = !newValue.isEmpty
        }
        
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == reasonTextView {
            placeholderText.isHidden = !reasonTextView.text.isEmpty
        }
    }
    
}

// MARK: - UITextFieldDelegate

extension GiveKudosViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == categoryTextField, textField.text?.isEmpty == true, achievements != nil && !achievements.isEmpty {
            // The user has not selected a value so we need to ensure our
            // selection matches the default pickerView selection
            self.selectedAchievementIndex = 0
        }
    }
}

// MARK: - UIPickerViewDataSource

extension GiveKudosViewController: UIPickerViewDataSource {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return achievements[row].title
    }
    
    @objc(numberOfComponentsInPickerView:) func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if achievements != nil {
            return achievements.count
        } else {
            return 0
        }
    }
}

// MARK: - UIPickerViewDelegate

extension GiveKudosViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedAchievementIndex = achievements.isEmpty ? nil : row
        categoryTextField.resignFirstResponder()
    }
}

// MARK: - SelectPeopleViewControllerDelegate

extension GiveKudosViewController: SelectPeopleViewControllerDelegate {
    func didSelectPersons(_ persons: [Persons]) {
        self.selectedPerson = persons.first
    }
}
