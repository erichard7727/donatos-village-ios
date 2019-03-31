//
//  AchievementImage.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 9/15/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

@IBDesignable
class AchievementImageView: UIView {
    var imageView: UIImageView!
    
    var progress: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    var badgeNumber: Int = 0
    
    fileprivate var circlePathLayer: CAShapeLayer!
    fileprivate var circleProgressLayer: CAShapeLayer!
    var radius: CGFloat
    
    required init?(coder aDecoder: NSCoder) {
        self.radius = 40.0
        
        imageView = UIImageView()
        circlePathLayer = CAShapeLayer()
        circleProgressLayer = CAShapeLayer()
        
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        self.radius = frame.width
        let imageFrame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        imageView = UIImageView(frame: imageFrame)
        imageView.layer.cornerRadius = imageView.frame.size.height / 2
        imageView.clipsToBounds = false
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.white
        imageView.layer.cornerRadius = imageFrame.height / 2
        
        circlePathLayer = CAShapeLayer()
        circleProgressLayer = CAShapeLayer()
        
        super.init(frame: frame)
    }
    
    deinit {
        imageView = nil
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func draw(_ rect: CGRect) {
        self.backgroundColor = UIColor.clear
        self.addSubview(imageView)
        
        progress = (progress * (2 * CGFloat(Double.pi))) - CGFloat(Double.pi / 2)
        
        circlePathLayer.frame = bounds
        var circleFrame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        circleFrame.origin.x = circlePathLayer.bounds.midX - circleFrame.midX
        circleFrame.origin.y = circlePathLayer.bounds.midY - circleFrame.midY
        circlePathLayer.path = UIBezierPath(ovalIn: circleFrame).cgPath
        let center = CGPoint(x: frame.width / 2, y: frame.width / 2)
        
        circlePathLayer.frame = bounds
        circlePathLayer.lineWidth = 5
        circlePathLayer.fillColor = UIColor.clear.cgColor
        circlePathLayer.strokeColor = UIColor.vlgGray.cgColor
        layer.addSublayer(circlePathLayer)
        
        circleProgressLayer.frame = circleFrame
        circleProgressLayer.path = UIBezierPath(arcCenter: center, radius: circleFrame.width / 2 , startAngle: -CGFloat(Double.pi / 2), endAngle: progress, clockwise: true).cgPath
        circleProgressLayer.lineWidth = 5
        circleProgressLayer.fillColor = UIColor.clear.cgColor
        circleProgressLayer.strokeColor = UIColor.vlgGreen.cgColor
        
        layer.addSublayer(circleProgressLayer)
        
        if badgeNumber > 0 {
            let x = (center.x) + ((frame.width / 2) * cos(45))
            let y = (center.y - 20) + ((frame.height / 2) * sin(45))
            let textView = UILabel(frame: CGRect(x: x, y: y, width: 26, height: 26))
            textView.backgroundColor = UIColor(red: 156/255.0, green: 32/255.0, blue: 101/255.0, alpha: 1)
            textView.textColor = UIColor.white
            textView.font = UIFont(name: "ProximaNova-SemiBold", size: 15.0)
            textView.adjustsFontSizeToFitWidth = true
            textView.textAlignment = .center
            textView.baselineAdjustment = .alignCenters
            textView.layer.cornerRadius = textView.frame.height / 2
            textView.layer.masksToBounds = true
            textView.text = "\(badgeNumber)"
            self.addSubview(textView)
        }
    }
}
