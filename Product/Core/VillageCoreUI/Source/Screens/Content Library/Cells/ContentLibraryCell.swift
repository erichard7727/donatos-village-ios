//
//  ContentLibraryCell.swift
//  VillageCore
//
//  Created by Michael Miller on 2/15/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

final class ContentLibraryCell: UITableViewCell {
    
    var filetype: ContentLibraryItem.FileType = .directory {
        didSet {
            switch filetype {
            case .directory:
                fileIcon.image = UIImage.named("content-folder")
            case .contentPage:
                fileIcon.image = UIImage.named("content-page")
            case .link:
                fileIcon.image = UIImage.named("content-link")
            case .pdf:
                fileIcon.image = UIImage.named("content-file")
            case .image:
                fileIcon.image = UIImage.named("content-image")
            case .file:
                fileIcon.image = UIImage.named("content-file")
            }
            fileIconWidth.constant = 30
            fileIconHeight.constant = 30
        }
    }
    
    @IBOutlet weak var fileIcon: UIImageView!
    @IBOutlet weak var fileIconWidth: NSLayoutConstraint!
    @IBOutlet weak var fileIconHeight: NSLayoutConstraint!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var modifiedLabel: UILabel!
}
