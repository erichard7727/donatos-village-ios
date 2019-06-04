//
//  StreamViewControllerBehaviors.swift
//  VillageCoreUI
//
//  Created by Colin Drake on 3/11/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import Foundation
import UIKit
import SlackTextViewController

/// Provides the "standard" editing UI for stream view controllers.
class StandardStreamEditingUIBehavior: ViewControllerLifecycleBehavior {
    
    func afterLoading(_ viewController: UIViewController) {
        guard let viewController = viewController as? SLKTextViewController else { return }
        
        viewController.textView.placeholder = "Message"
        viewController.textView.keyboardType = .emailAddress
        viewController.rightButton.setTitleColor(UIColor(red: 202/255.0, green: 64/255.0, blue: 39/255.0, alpha: 1.0), for: .normal)
        viewController.leftButton.setImage(UIImage.named("add-icon"), for: .normal)
        viewController.leftButton.tintColor = UIColor.vlgGray
    }
    
}
