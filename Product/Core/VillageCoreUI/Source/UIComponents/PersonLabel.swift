//
//  PersonLabel.swift
//  VillageCore
//
//  Created by Justin Munger on 5/3/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

class PersonLabel: NSObject {
    let view: UILabel = UILabel()
    var selected: Bool = false {
        didSet {
            selected ? self.highlight() : self.unhighlight()
        }
    }
    
    weak var delegate: SelectPeopleViewController?
    
    
    init(delegate: SelectPeopleViewController?, title: String, font: UIFont?) {
        
        self.delegate = delegate
        
        super.init()
        
        view.text = " \(title) "
        view.font = font
        view.textColor = UIColor.vlgBlue
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 2
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.vlgGray.cgColor
        view.sizeToFit()
        
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(clicked(_:))
        ))
        
    }
    
    func highlight() {
        view.backgroundColor = UIColor.vlgLightGray
    }
    
    func unhighlight() {
        view.backgroundColor = UIColor.clear
    }
    
    @objc func clicked(_ sender: UITapGestureRecognizer) {
        delegate?.clickPersonLabel(self)
    }
}
