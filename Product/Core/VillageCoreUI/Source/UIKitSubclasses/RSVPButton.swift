//
//  RSVPButton.swift
//  VillageCoreUI
//
//  Created by Jack Miller on 9/23/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

class RSVPButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configureView()
    }
    
    func configureView() {
        self.layer.cornerRadius = self.bounds.height / 2.0
        self.setSelectedStyle(false)
    }
    
    func setSelectedStyle(_ selected: Bool) {
        if selected {
            self.backgroundColor = UIColor(red: 139/255.0, green: 154/255.0, blue: 27/255.0, alpha: 1.0)
            self.setTitleColor(.white, for: .normal)
        } else {
            self.backgroundColor = UIColor(red: 107/255.0, green: 122/255.0, blue: 131/255.0, alpha: 0.1)
            self.setTitleColor(.black, for: .normal)
        }
    }
    
}
