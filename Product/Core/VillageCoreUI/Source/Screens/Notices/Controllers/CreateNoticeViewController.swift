//
//  CreateNoticeViewController.swift
//  VillageContainerApp
//
//  Created by Justin Munger on 8/31/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

class CreateNoticeViewController: UIViewController {

    @IBOutlet weak var noticeBodyTextView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var titleTextField: IndentedTextField!
    
    let everyoneOption = "Everyone"
    let targetGroupOption = "Targeted Group"
    
    var progressIndicator: ProgressIndicator!
    let sendToOptions = ["Everyone", "Targeted Group"]
    var containerHeight: CGFloat = 0
    var containerTopMargin: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)
        ])
        
//        let pickerView = UIPickerView()
//        pickerView.delegate = self
//        
//        sendToTextField.inputView = pickerView
//        
//        sendToTextField.text = sendToOptions[0]
//        
//        sendToTextField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        self.progressIndicator = ProgressIndicator.progressIndicatorInView(self.view)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
   
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
    }
    
    @IBAction func createNoticeButtonPressed(_ sender: UIButton) {
        progressIndicator.show()
        guard let title = titleTextField.text, let body = noticeBodyTextView.text else {
            return
        }
        
        if title == "" || body == "" {
            return
        }
        
        #warning("TODO - Implement create notice endpoint")
        assertionFailure()
        
//        noticeService.postNotice(personId: User.current.personId, title: title, body: body) {
//            [weak self] result in
//            guard let strongSelf = self else {
//                return
//            }
//            switch result {
//            case .success:
//                strongSelf.progressIndicator.hide()
//                if let navigationController = strongSelf.navigationController {
//                    navigationController.popViewController(animated: true)
//                }
//            case .error(let error):
//                strongSelf.progressIndicator.hide()
//                if let httpErrorCode = error.httpErrorCode , httpErrorCode == 401 {
//                    return
//                }
//
//                if let httpErrorCode = error.httpErrorCode , httpErrorCode == 403 {
//                    let alert = UIAlertController.dismissableAlert("Error", message: "Must have administrative privileges")
//                    strongSelf.present(alert, animated: true, completion: nil)
//                }
//            }
//        }
    }
    
}

extension CreateNoticeViewController {
    @objc func done() {
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset:UIEdgeInsets = self.scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height
        self.scrollView.contentInset = contentInset
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        self.scrollView.contentInset = contentInset
    }
}

extension CreateNoticeViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sendToOptions.count
    }
}
//
//extension CreateNoticeViewController: UIPickerViewDelegate {
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return sendToOptions[row]
//    }
//    
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        sendToTextField.text = sendToOptions[row]
//        if sendToTextField.text == everyoneOption {
//            groupDepartmentContainerHeightConstraint.constant = 0
//            groupDepartmentContainerTopConstraint.constant = 0
//            
//            UIView.animate(withDuration: 0.3, animations: {
//                self.view.layoutIfNeeded()
//            })
//        } else if sendToTextField.text == targetGroupOption {
//            groupDepartmentContainerHeightConstraint.constant = containerHeight
//            groupDepartmentContainerTopConstraint.constant = containerTopMargin
//            
//            UIView.animate(withDuration: 0.3, animations: {
//                self.view.layoutIfNeeded()
//            })
//        }
//    }
//}

extension CreateNoticeViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        scrollView.setContentOffset(textField.bounds.origin, animated: true)
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50))
        toolBar.barStyle = UIBarStyle.default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(done))
        toolBar.items = [flexSpace, doneButton]
        toolBar.sizeToFit()
        textField.inputAccessoryView = toolBar
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == titleTextField {
            noticeBodyTextView.becomeFirstResponder()
        }
        return false
    }
}

extension CreateNoticeViewController: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        let point = CGPoint(x: textView.bounds.origin.x, y: textView.bounds.origin.y + textView.bounds.height)
        scrollView.setContentOffset(point, animated: true)
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50))
        toolBar.barStyle = UIBarStyle.default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(done))
        toolBar.items = [flexSpace, doneButton]
        toolBar.sizeToFit()
        textView.inputAccessoryView = toolBar
        
        return true
    }
}

