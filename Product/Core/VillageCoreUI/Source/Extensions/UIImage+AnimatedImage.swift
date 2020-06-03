//
//  UIImage+AnimatedImage.swift
//  VillageCoreUI
//
//  Created by Justin Munger on 12/12/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import ImageIO
import UIKit

public extension UIImage
{
    fileprivate struct AssociatedKeys {
        static var AnimatedImage = "AnimatedImage"
    }
    
    convenience init?(animatedImageData:Data, desiredClarity: Float = 1.0) {
        self.init()
        
        guard let imageSource = CGImageSourceCreateWithData(animatedImageData as CFData, nil) else {
            return nil
        }
        
        if CGImageSourceGetCount(imageSource) <= 1 {
            return nil
        }
        
        guard let animatedImage = AnimatedImage(imageSource: imageSource, desiredClarity: desiredClarity) else {
            return nil
        }
        
        self.animatedImage = animatedImage
    }
    
    var imageSource: CGImageSource {
        get {
            return animatedImage.imageSource
        }
    }
    
    var refreshFactor: Int {
        get {
            return animatedImage.displayRefreshFactor
        }
    }
    
    var imageSize: Int {
        get {
            return animatedImage.imageSize
        }
    }
    
    var imageNumber: Int {
        get {
            return animatedImage.imageCount
        }
    }
    
    var displayOrder: [Int] {
        get {
            return animatedImage.displayOrder
        }
    }
    
    var animated: Bool {
        get {
            guard let animatedImage = objc_getAssociatedObject(self, &AssociatedKeys.AnimatedImage) as? AnimatedImage else {
                return false
            }
            return animatedImage.animated
        }
    }
    
    static func containsAnimatedImage(data: Data) -> Bool {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return false
        }
        
        if CGImageSourceGetCount(imageSource) <= 1 {
            return false
        }
        
        let imageProperties = AnimatedImage.getImageProperties(from: imageSource)
        guard AnimatedImage.getFrameProperties(from: imageProperties) != nil else {
            return false
        }
        
        return true
    }
    
    static func containsAnimatedImage(image: UIImage) -> Bool {
        
        guard let cgImage = image.cgImage, let dataProvider = cgImage.dataProvider, let imageSource = CGImageSourceCreateWithDataProvider(dataProvider, nil) else {
            return false
        }
        
        if CGImageSourceGetCount(imageSource) <= 1 {
            return false
        }
        
        let imageProperties = AnimatedImage.getImageProperties(from: imageSource)
        guard AnimatedImage.getFrameProperties(from: imageProperties) != nil else {
            return false
        }
        
        return true
        
    }
    
    fileprivate var animatedImage: AnimatedImage {
        get {
            return (objc_getAssociatedObject(self, &AssociatedKeys.AnimatedImage) as! AnimatedImage)
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.AnimatedImage, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

private class AnimatedImage {
    let imageSource: CGImageSource
    let imageSize: Int
    var displayRefreshFactor: Int
    var imageCount: Int
    var displayOrder: [Int]
    var animated: Bool = false
    
    init?(imageSource: CGImageSource, desiredClarity: Float) {
        let imageProperties = AnimatedImage.getImageProperties(from: imageSource)
        
        guard let frameProperties = AnimatedImage.getFrameProperties(from: imageProperties) else {
            return nil
        }
        
        let delayTimes = AnimatedImage.getDelayTimes(from: frameProperties)
        let clarityToUse = desiredClarity <= 0.0 || desiredClarity > 1.0 ? 1.0 : desiredClarity
        
        let maxFramesPerSecond = 60
        let framesPerSecond = [1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, maxFramesPerSecond]
        
        let refreshRatesPerSecond = framesPerSecond.map { currentFramesPerSecond in
            return maxFramesPerSecond / currentFramesPerSecond
        }
        
        let frameDisplayLengths = framesPerSecond.map { currentFramesPerSecond in
            return 1.0 / Float(currentFramesPerSecond)
        }
        
        let frameDisplayTimes = AnimatedImage.getFrameDisplayTimes(from: delayTimes)
        
        var imageCount: Int?
        var displayRefreshFactor: Int?
        var displayOrder: [Int]?
        
        for frameDisplayLengthsIndex in 0 ..< frameDisplayLengths.count {
            let displayPositionsAtCurrentFrameRate = frameDisplayTimes.map { displayPositionAtCurrentFrameRate in
                return Int(displayPositionAtCurrentFrameRate / frameDisplayLengths[frameDisplayLengthsIndex])
            }
            
            let framesLostAtCurrentFrameRate = Float(AnimatedImage.getNumberOfFramesLostAtCurrentFrameRate(for: displayPositionsAtCurrentFrameRate))
            let desiredFrameDisplayClarity = Float(displayPositionsAtCurrentFrameRate.count) * (1.0 - clarityToUse)
            let lastValidFrameDisplayLengthIndex = frameDisplayLengths.count - 1
            
            let animatedImageWillDisplayAtDesiredClarity = framesLostAtCurrentFrameRate <= desiredFrameDisplayClarity
            let noMoreValidFrameRatesToTestAgainst = frameDisplayLengthsIndex == lastValidFrameDisplayLengthIndex
            
            if animatedImageWillDisplayAtDesiredClarity || noMoreValidFrameRatesToTestAgainst {
                imageCount = displayPositionsAtCurrentFrameRate.last
                displayRefreshFactor = refreshRatesPerSecond[frameDisplayLengthsIndex]
                
                if let imageCount = imageCount {
                    displayOrder = AnimatedImage.generateFinalDisplayPositions(from: displayPositionsAtCurrentFrameRate, with: imageCount)
                }
                
                break
            }
        }
        
        guard let nonOptionalImageCount = imageCount,
            let imageSize = AnimatedImage.getImageSize(from: imageProperties, with: nonOptionalImageCount),
            let nonOptionalDisplayRefreshFactor = displayRefreshFactor,
            let nonOptionalDisplayOrder = displayOrder else {
                return nil
        }
        
        self.imageSource = imageSource
        self.imageSize = imageSize
        self.imageCount = nonOptionalImageCount
        self.displayRefreshFactor = nonOptionalDisplayRefreshFactor
        self.displayOrder = nonOptionalDisplayOrder
        self.animated = true
    }
    
    fileprivate static func getImageProperties(from imageSource: CGImageSource) -> [NSDictionary] {
        var imageProperties = [NSDictionary]()
        
        let imageCount = CGImageSourceGetCount(imageSource)
        
        for i in 0..<imageCount {
            imageProperties.append(CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil)!)
        }
        
        return imageProperties
    }
    
    fileprivate static func getImageSize(from imageProperties: [NSDictionary], with imageCount: Int) -> Int? {
        if let imageWidth = imageProperties[0][kCGImagePropertyPixelWidth as NSString] as? Int,
            let imageHeight = imageProperties[0][kCGImagePropertyPixelHeight as NSString] as? Int {
            return Int(imageHeight * imageWidth * 4) * imageCount / (1024 * 1024)
        } else {
            return nil
        }
    }
    
    fileprivate static func getFrameProperties(from imageProperties: [NSDictionary]) -> [NSDictionary]? {
        var frameProperties: [NSDictionary]?
        
        if imageProperties[0][kCGImagePropertyGIFDictionary as NSString] != nil {
            frameProperties = imageProperties.map { imageProperty in
                return imageProperty[kCGImagePropertyGIFDictionary as NSString] as! NSDictionary
            }
        } else if imageProperties[0][kCGImagePropertyPNGDictionary as NSString] != nil {
            frameProperties = imageProperties.map { imageProperty in
                return imageProperty[kCGImagePropertyPNGDictionary as NSString] as! NSDictionary
            }
        } else {
            frameProperties = nil
        }
        
        return frameProperties
    }
    
    fileprivate static func getDelayTimes(from frameProperties: [NSDictionary]) -> [Float] {
        let EPS: Float = 1e-6
        let frameDelays: [Float] = frameProperties.compactMap() { frameProperty in
            
            var delay: Float?
            delay = frameProperty[kCGImagePropertyGIFUnclampedDelayTime as NSString] as? Float
            
            if let nonOptionalDelay = delay, nonOptionalDelay < EPS {
                delay = frameProperty[kCGImagePropertyGIFDelayTime as NSString] as? Float
            }
            
            return delay
        }
        
        return frameDelays
    }
    
    fileprivate static func generateFinalDisplayPositions(from displayPositionsAtFrameRate: [Int], with imageCount: Int) -> [Int] {
        var finalDisplayPositions = [Int]()
        
        var indexOfold = 0, indexOfnew = 1
        while(indexOfnew <= imageCount) {
            if(indexOfnew <= displayPositionsAtFrameRate[indexOfold]) {
                finalDisplayPositions.append(indexOfold)
                indexOfnew += 1
            } else{
                indexOfold += 1
            }
        }
        
        return finalDisplayPositions
    }
    
    fileprivate static func getFrameDisplayTimes(from frameDelayLengths: [Float]) -> [Float] {
        guard frameDelayLengths.count > 0 else { return [] }

        var frameDisplayTimes: [Float] = frameDelayLengths
        for currentFrameDisplayTime in 1 ..< frameDisplayTimes.count {
            frameDisplayTimes[currentFrameDisplayTime] += frameDisplayTimes[currentFrameDisplayTime - 1]
        }
        
        return frameDisplayTimes
    }
    
    fileprivate static func getNumberOfFramesLostAtCurrentFrameRate(for frameDisplayPositions: [Int]) -> Int {
        guard frameDisplayPositions.count > 0 else { return 0 }

        var numberOfFramesLostAtCurrentFrameRate = 0
        for displayPositionIndex in 1 ..< frameDisplayPositions.count {
            if frameDisplayPositions[displayPositionIndex] == frameDisplayPositions[displayPositionIndex - 1] {
                numberOfFramesLostAtCurrentFrameRate += 1
            }
        }
        
        return numberOfFramesLostAtCurrentFrameRate
    }
}

