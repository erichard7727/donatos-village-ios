//
//  TabBarView.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 9/13/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

@objc protocol TabItemViewDelegate {
    func tabWasClicked(result: String)
}

//Used in pages requiring a custom tab bar. Create a center point and animates outward towards the edges

@IBDesignable
class TabItemView: UIView {
    var highLighted = false
    
    @IBOutlet weak var tabButton: UIButton!
    @IBOutlet weak var tabBarUnderline: UIView!
    @IBOutlet var view: UIView!
    
    weak var delegate: TabItemViewDelegate?
    
    let orangeColor = UIColor.named("vlgOrange")!
    let grayTextColor = UIColor.named("vlgMediumGray")!
    let grayBarColor = UIColor.groupTableViewBackground
    
    var rightPath = UIBezierPath()
    var pathLayerRight = CAShapeLayer()
    var leftPath = UIBezierPath()
    var pathLayerLeft = CAShapeLayer()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initFromXib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initFromXib()
    }
    
    func initFromXib() {
        let bundle = Bundle(for: TabItemView.self)
        
        bundle.loadNibNamed("TabItem", owner: self, options: nil)
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.frame = self.bounds
        self.addSubview(view)
    }
    
    @IBAction func tabButtonClicked(_ sender: UIButton) {
        //changeHighlight(sender: sender)
        delegate?.tabWasClicked(result: (sender.titleLabel?.text)!)
    }
    
    //animate the highlight from the center outwards at a duration of 0.3 seconds
    func changeHighlight(sender: Any? = nil) {
        if !highLighted {
            selectInitialTab()
            
            let leftPathAnimation: CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
            leftPathAnimation.duration = 0.35
            leftPathAnimation.fromValue = 0.0
            leftPathAnimation.toValue = 1.0
            leftPathAnimation.isAdditive = false
            leftPathAnimation.isCumulative = false
            leftPathAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
            leftPathAnimation.isRemovedOnCompletion = true
            pathLayerLeft.add(leftPathAnimation, forKey: "leftPathAnimation")
            
            let rightPathAnimation: CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
            rightPathAnimation.duration = 0.35
            rightPathAnimation.fromValue = 0.0
            rightPathAnimation.toValue = 1.0
            rightPathAnimation.isAdditive = false
            rightPathAnimation.isCumulative = false
            rightPathAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
            rightPathAnimation.isRemovedOnCompletion = true
            pathLayerRight.add(rightPathAnimation, forKey: "rightPathAnimation")
            
        }
    }
    
    func removeHighlight(sender: Any? = nil) {
        self.tabButton.setTitleColor(self.grayTextColor, for: .normal)
        self.pathLayerRight.removeAllAnimations()
        self.pathLayerLeft.removeAllAnimations()
        self.pathLayerRight.removeFromSuperlayer()
        self.pathLayerLeft.removeFromSuperlayer()
        
        rightPath = UIBezierPath()
        pathLayerRight = CAShapeLayer()
        leftPath = UIBezierPath()
        pathLayerLeft = CAShapeLayer()
        
        self.highLighted = false
    }
    
    //Create a left path and right path with points in the center and endpoints at the edges
    func selectInitialTab() {
        self.tabButton.setTitleColor(self.orangeColor, for: .normal)
        
        self.rightPath.move(to: CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height - 3))
        self.rightPath.addLine(to: CGPoint(x: self.frame.size.width, y: self.frame.size.height - 3))
        
        self.pathLayerRight.frame = self.bounds
        self.pathLayerRight.path = self.rightPath.cgPath
        self.pathLayerRight.strokeColor = self.orangeColor.cgColor
        self.pathLayerRight.lineWidth = 6.0
        self.pathLayerRight.lineJoin = CAShapeLayerLineJoin.bevel
        
        self.leftPath.move(to: CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height - 3))
        self.leftPath.addLine(to: CGPoint(x: 0, y: self.frame.size.height - 3))
        
        
        self.pathLayerLeft.frame = self.bounds
        self.pathLayerLeft.path = self.leftPath.cgPath
        self.pathLayerLeft.strokeColor = self.orangeColor.cgColor
        self.pathLayerLeft.lineWidth = 6.0
        self.pathLayerLeft.lineJoin = CAShapeLayerLineJoin.bevel
        
        self.layer.addSublayer(self.pathLayerRight)
        self.layer.addSublayer(self.pathLayerLeft)
        
        highLighted = true
    }
}
