//
//  IndentedTextField.swift
//  VillageCoreUI
//
//  Created by Justin Munger on 9/2/16.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

class IndentedTextField: UITextField {
    let edgeInsets = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: edgeInsets)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: edgeInsets)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: edgeInsets)
    }
}
