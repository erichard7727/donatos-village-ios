//
//  NibView.swift
//  VillageCoreUI
//
//  Created by Jack Miller on 4/12/18.
//  Copyright © 2018 Dynamit. All rights reserved.
//

///Inspired by this post: https://medium.com/theappspace/swift-custom-uiview-with-xib-file-211bb8bbd6eb

import UIKit

class NibControl: UIControl {
    var view: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        xibSetup()
    }
    
    open func setupViews() {
        //extension point for subclasses to do initial setup
    }
    
    private func xibSetup() {
        view = loadNib()
        // use bounds not frame or it'll be offset
        view.frame = bounds
        // Adding custom subview on top of our view
        addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[childView]|",
                                                      options: [],
                                                      metrics: nil,
                                                      views: ["childView": view!]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[childView]|",
                                                      options: [],
                                                      metrics: nil,
                                                      views: ["childView": view!]))
        
        DispatchQueue.main.async {
            self.setupViews()
        }
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.setupViews()
    }
}

class NibView: UIView {
    var view: UIView!
    override init(frame: CGRect) {
        super.init(frame: frame)

        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        xibSetup()
    }
    
    open func setupViews() {
        //extension point for subclasses to do initial setup
    }
    
    private func xibSetup() {
        backgroundColor = UIColor.clear
        view = loadNib()
        // use bounds not frame or it'll be offset
        view.frame = bounds
        // Adding custom subview on top of our view
        addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[childView]|",
                                                      options: [],
                                                      metrics: nil,
                                                      views: ["childView": view!]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[childView]|",
                                                      options: [],
                                                      metrics: nil,
                                                      views: ["childView": view!]))
        
        DispatchQueue.main.async {
            self.setupViews()
        }
        
    }
}

extension UIView {
    /** Loads instance from nib with the same name. */
    func loadNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        
        let nibName = type(of: self).description().components(separatedBy: ".").last!
        
        if let _ = bundle.path(forResource: nibName, ofType: "nib") {
            let nib = UINib(nibName: nibName, bundle: bundle)
            return nib.instantiate(withOwner: self, options: nil).first as! UIView
            
        } else if let superNib = self.findSuperNib(in: bundle) {
            return superNib.instantiate(withOwner: self, options: nil).first as! UIView
        }
        
        assertionFailure("unable to find nib for class: \(nibName)")
        return UIView()
    }
        

    private func findSuperNib(in bundle: Bundle) -> UINib? {
        
        var check: AnyClass? = self.superclass
        
        while let superClass = check {
            let nibName = superClass.description().components(separatedBy: ".").last!
            
            if let _ = bundle.path(forResource: nibName, ofType: "nib") {
                return UINib(nibName: nibName, bundle: bundle)
            }
            
            check = check?.superclass()
        }
        
        return nil
    }
        
}

