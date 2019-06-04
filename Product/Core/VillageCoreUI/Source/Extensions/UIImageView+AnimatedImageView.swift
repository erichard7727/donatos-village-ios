//
//  UIImageView+AnimatedImageView.swift
//  VillageCoreUI
//
//  Created by Justin Munger on 12/12/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import ImageIO
import UIKit

public extension UIImageView {
    
    fileprivate struct AssociatedKeys {
        static var AnimatedImageView = "AnimatedImageView"
    }
    
    convenience init(animatedImage image: UIImage, memoryLimit: Int = 20){
        self.init()
        setAnimatedImage(animatedImage: image, memoryLimit: memoryLimit)
    }
    
    func setAnimatedImage(animatedImage image: UIImage, memoryLimit: Int = 20) {
        let shouldCache = false
        
        self.animatedImageViewStorage = AnimatedImageViewStorage(animatedImage: image, shouldCache: shouldCache)
    }
    
    func playAnimatedImage() {
        if let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
        
        let timer: CADisplayLink
        
        if shouldCache {
            timer = CADisplayLink(target: self, selector: #selector(UIImageView.updateFrameWithCache))
        } else {
            timer = CADisplayLink(target: self, selector: #selector(UIImageView.updateFrameWithoutCache))
        }
        
        timer.preferredFramesPerSecond = self.animatedImageViewStorage.aImage.refreshFactor
        timer.add(to: .main, forMode: RunLoop.Mode.common)
        
        self.timer = timer
        
        self.animatedImageViewStorage.needToPlay = true
    }
    
    func stopAnimatedImage() {
        self.animatedImageViewStorage.needToPlay = false
        if let timer = self.timer {
            timer.remove(from: .main, forMode: RunLoop.Mode.common)
            self.timer = nil
        }
    }
    
    fileprivate var shouldPlay: Bool {
        get {
            return animatedImageViewStorage.needToPlay
        }
        set {
            animatedImageViewStorage.needToPlay = newValue
        }
    }
    
    fileprivate var animatedImage: UIImage {
        get {
            return animatedImageViewStorage.aImage
        }
        set {
            animatedImageViewStorage.aImage = newValue
        }
    }
    
    fileprivate var displayOrderIndex: Int {
        get {
            return animatedImageViewStorage.displayOrderIndex
        }
        set {
            animatedImageViewStorage.displayOrderIndex = newValue
        }
    }
    
    fileprivate var currentImage: UIImage? {
        get {
            return animatedImageViewStorage.currentImage
        }
        set {
            animatedImageViewStorage.currentImage = newValue
        }
    }
    
    fileprivate var imageCache: NSCache<AnyObject, AnyObject>? {
        get {
            return animatedImageViewStorage.cache
        }
    }
    
    fileprivate var timer: CADisplayLink? {
        get {
            return animatedImageViewStorage.timer
        } set {
            animatedImageViewStorage.timer = newValue
        }
    }
    
    fileprivate var shouldCache: Bool {
        get {
            return animatedImageViewStorage.shouldCache
        }
    }
    
    @objc func updateFrameWithoutCache() {
        if self.shouldPlay == true {
            self.image = self.currentImage
            DispatchQueue.global(qos: .userInteractive).async {
                let imageSource = self.animatedImage.imageSource
                let imageIndex = self.animatedImage.displayOrder[self.displayOrderIndex]
                let options = [(kCGImageSourceShouldCacheImmediately as String): kCFBooleanFalse] as CFDictionary?
                
                if let currentCGImage = CGImageSourceCreateImageAtIndex(imageSource, imageIndex, options) {
                    self.currentImage = UIImage(cgImage: currentCGImage)
                }
                
                self.displayOrderIndex = (self.displayOrderIndex + 1) % self.animatedImage.imageNumber
            }
        }
    }
    
    @objc func updateFrameWithCache() {
        if self.shouldPlay == true {
            if let cache = self.imageCache {
                self.image = cache.object(forKey: self.displayOrderIndex as AnyObject) as? UIImage
                self.displayOrderIndex = (self.displayOrderIndex + 1) % self.animatedImage.imageNumber
            }
        }
    }
    
    func containsAnimatedImage() -> Bool {
        guard let animatedImageViewStorage = objc_getAssociatedObject(self, &AssociatedKeys.AnimatedImageView) as? AnimatedImageViewStorage else {
            return false
        }
        
        return animatedImageViewStorage.aImage.animated
    }
    
    fileprivate var animatedImageViewStorage: AnimatedImageViewStorage {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.AnimatedImageView) as! AnimatedImageViewStorage
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.AnimatedImageView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
}

private class AnimatedImageViewStorage {
    var aImage: UIImage
    var displayOrderIndex: Int
    var needToPlay: Bool
    var currentImage: UIImage?
    var cache: NSCache<AnyObject, AnyObject>?
    var timer: CADisplayLink?
    var shouldCache: Bool
    
    init(animatedImage: UIImage, shouldCache: Bool, needToPlay: Bool = false) {
        self.aImage = animatedImage
        self.displayOrderIndex = 0
        self.needToPlay = needToPlay
        self.shouldCache = shouldCache
        
        if let currentCGImage = CGImageSourceCreateImageAtIndex(animatedImage.imageSource, 0, nil) {
            self.currentImage = UIImage(cgImage: currentCGImage)
        }
        
        if shouldCache {
            DispatchQueue.global(qos: .userInteractive).async {
                let cache = NSCache<AnyObject, AnyObject>()
                for i in 0 ..< self.aImage.displayOrder.count {
                    let imageSource = self.aImage.imageSource
                    let imageIndex = self.aImage.displayOrder[i]
                    let options = [(kCGImageSourceShouldCacheImmediately as String): kCFBooleanTrue] as CFDictionary?
                    
                    if let currentCGImage = CGImageSourceCreateImageAtIndex(imageSource, imageIndex, options) {
                        let image = UIImage(cgImage: currentCGImage)
                        cache.setObject(image, forKey: i as AnyObject)
                    }
                }
                
                self.cache = cache
            }
        }
    }
}


