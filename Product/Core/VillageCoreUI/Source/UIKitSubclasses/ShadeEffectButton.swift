//
//  ShadeEffectButton.swift
//  ClubCorp
//
//  Created by Jack Miller on 4/9/18.
//  Copyright © 2018 Dynamit. All rights reserved.
//

import UIKit

class ShadeEffectButton: UIButton {

    var shadeColor: UIColor = UIColor.black.withAlphaComponent(0.1)
    
    var normalBackgroundColor: UIColor?
    
    override var backgroundColor: UIColor? {
        didSet {
            if backgroundColor != shadeColor {
                normalBackgroundColor = backgroundColor
            }
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                UIView.animate(withDuration: 0.15) {
                    self.backgroundColor = self.shadeColor
                }
            }
            else {
                UIView.animate(withDuration: 0.15) {
                    self.backgroundColor = self.normalBackgroundColor
                }
            }
        }
    }

}
