//
//  ProgessBarView.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 9/9/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit

@IBDesignable
class ProgressBarView: UIView {
    var progress = 10.0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func draw(_ rect: CGRect) {
        let barRect = CGRect(x: 0, y: 0, width: frame.width, height: 40)
        
        let path = UIBezierPath(roundedRect: barRect, cornerRadius: 30)
        
        UIColor.vlgLightGray.setFill()
        path.fill()
        
        let percentage = (Double(frame.width) * progress) / 100
        
        let progressRect = CGRect(x: 0, y: 0, width: CGFloat(percentage), height: 40)
        
        let progressLayer = CAShapeLayer()
        progressLayer.path = UIBezierPath(roundedRect: progressRect, byRoundingCorners: [.topLeft, .bottomLeft], cornerRadii: CGSize(width: CGFloat(30), height: frame.height)).cgPath
        progressLayer.fillColor = UIColor.vlgGreen.cgColor
        layer.addSublayer(progressLayer)
        
        let coverLayer = CAShapeLayer()
        coverLayer.path = UIBezierPath(roundedRect: barRect, cornerRadius: 30).cgPath
        coverLayer.fillRule = CAShapeLayerFillRule.evenOdd
        coverLayer.fillColor = UIColor.white.cgColor
        layer.mask = coverLayer
    }
}
