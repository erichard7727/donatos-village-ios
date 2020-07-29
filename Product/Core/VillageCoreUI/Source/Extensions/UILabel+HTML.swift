//
//  UILabel+HTML.swift
//  VillageCoreUI
//
//  Created by Jack Miller on 9/23/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

extension UILabel {
    func setHTMLFromString(text: String) {
        
        let modifiedFont = NSString(format:"<span style=\"font-family: \(self.font.fontName); font-size: \(self.font.pointSize)\">%@</span>" as NSString, text)
        
        guard let data = modifiedFont.data(using: String.Encoding.unicode.rawValue, allowLossyConversion: true) else {
            assertionFailure("unable to create html data")
            return
        }
        
        guard let attrStr = try? NSAttributedString(
            data: data,
            options: [NSAttributedString.DocumentReadingOptionKey.documentType:NSAttributedString.DocumentType.html, NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil) else {
            assertionFailure("unable to set html attributed string")
            return
        }
        
        self.attributedText = attrStr
    }
}
