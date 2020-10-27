//
//  EditSettingsController.swift
//  VillageCore
//
//  Created by Colin Drake on 2/29/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import AlamofireImage
import VillageCore

/// User settings view controller.
final class EditSettingsController: UIViewController {
    let MAX_UPLOAD_SIZE = 2097152
    
    var settingsController: SettingsController!
    
    var avatarImage: UIImage?
    
    lazy var imagePicker: UIImagePickerController = {
        let ip = UIImagePickerController()
        return ip
    }()

    var progressIndicator: ProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)
        ])
    
        progressIndicator = ProgressIndicator.progressIndicatorInView(self.view)
        
        if let url = User.current.avatarURL {
            let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                size:  self.settingsController.avatarImageView.frame.size,
                radius:  self.settingsController.avatarImageView.frame.size.height / 2
            )
            
             self.settingsController.avatarImageView.vlg_setImage(withURL: url, filter: filter)
        }
    }
    
    func scaleImage(_ attachmentImage: UIImage, desiredImageWidth: CGFloat) -> UIImage {
        let imageWidth = attachmentImage.size.width
        let widthScale = (desiredImageWidth / imageWidth) < 1.0 ? (desiredImageWidth / imageWidth) : 1.0
        
        let size = attachmentImage.size.applying(CGAffineTransform(scaleX: widthScale, y: widthScale))
        let hasAlpha = true
        let scale: CGFloat = 0.0
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        attachmentImage.draw(in: CGRect(origin: CGPoint.zero, size: size))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SettingsController" {
            guard let viewController = segue.destination as? SettingsController else {
                fatalError("SettingsController not found")
            }
            
            viewController.delegate = self
            
            settingsController = viewController
        }
    }
    
}

extension EditSettingsController: SettingsControllerDelegate {
    func selectAvatarPressed() {
        let actionSheetController: UIAlertController = UIAlertController(
            title: "Upload Avatar",
            message: "Choose an image from the following options.",
            preferredStyle: .actionSheet
        )
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            // Dismissed
        }
        actionSheetController.addAction(cancelAction)
        
        // Camera Roll
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) {
            let takePictureAction: UIAlertAction = UIAlertAction(title: "Camera", style: .default) { action -> Void in
                self.imagePicker.delegate = self
                self.imagePicker.sourceType = .camera
                self.imagePicker.cameraCaptureMode = .photo
                self.imagePicker.allowsEditing = false
                self.present(self.imagePicker, animated: true, completion: nil)
            }
            actionSheetController.addAction(takePictureAction)
        }
        
        // Photo Gallery
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.savedPhotosAlbum){
            let choosePictureAction: UIAlertAction = UIAlertAction(title: "Gallery", style: .default) { action -> Void in
                self.imagePicker.delegate = self
                self.imagePicker.sourceType = .savedPhotosAlbum;
                self.imagePicker.allowsEditing = false
                self.present(self.imagePicker, animated: true, completion: nil)
            }
            actionSheetController.addAction(choosePictureAction)
        }
        
        present(actionSheetController, animated: true, completion: nil)
    }
    
    @IBAction func savePressed(_ sender: Any? = nil) {
        guard var mutablePerson = settingsController.person else {
            assertionFailure()
            return
        }
        
        if let firstName = settingsController.firstNameTextField.text, !firstName.isEmpty {
            mutablePerson.firstName = firstName
        }
        
        if let lastName = settingsController.lastNameTextField.text, !lastName.isEmpty {
            mutablePerson.lastName = lastName
        }
        
        if let email = settingsController.emailTextField.text, !email.isEmpty {
            mutablePerson.emailAddress = email
        }
        
        mutablePerson.jobTitle = settingsController.titleTextField.text ?? ""
        mutablePerson.phone = settingsController.phoneTextField.text ?? ""
        mutablePerson.twitter = settingsController.twitterTextField.text ?? ""
        
        progressIndicator.show()
        
        firstly {
            mutablePerson.updateDetails(avatarData: avatarImage?.pngData())
        }.then { [weak self] (updatedPerson) in
            User.current.update(from: updatedPerson)
            self?.settingsController.person = updatedPerson
            self?.settingsController.populatePersonData()
            
            let alert = UIAlertController.dismissable(title: "Success", message: "Successfully updated person.")
            self?.present(alert, animated: true, completion: nil)
        }.catch { [weak self] (error) in
            let alert = UIAlertController.dismissable(title: "Error", message: error.localizedDescription)
            self?.present(alert, animated: true, completion: nil)
        }.always { [weak self] in
            self?.progressIndicator.hide()
        }
    }
    
    func logoutPressed() {
        User.current.logout()
    }
}

extension EditSettingsController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        self.dismiss(animated: true, completion: nil)
        
        guard
            let adjustedImage = ((info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage))?.vlg_orientedUp(),
            let imageData = adjustedImage.pngData()
        else {
            let alert = UIAlertController.dismissable(title: "Error", message: "Could not get avatar image!")
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if imageData.count > MAX_UPLOAD_SIZE {
            let oldSize: CGSize = adjustedImage.size
            let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
            avatarImage = UIImage(data: adjustedImage.resizeImage(imageSize: newSize, image: adjustedImage) as Data)
        } else {
            avatarImage = adjustedImage
        }
        
        settingsController.populateAvatarImage(adjustedImage)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
