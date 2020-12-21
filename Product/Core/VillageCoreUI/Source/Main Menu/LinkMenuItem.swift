//
//  LinkMenuItem.swift
//  VillageCoreUI
//
//  Created by Nikola Angelkovik on 12/17/20.
//  Copyright © 2020 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

protocol LinkMenuItemDelegate: AnyObject {
    func didSelectLinkMenuItem(_ linkMenuItemModel: LinkMenuItemModel)
}

final class LinkMenuItem: NibView {
    
    // MARK: Public Properties
    
    weak var delegate: LinkMenuItemDelegate?
    
    var linkMenuItemModel: LinkMenuItemModel? {
          didSet {
              title.text = linkMenuItemModel?.title
          }
    }
    
    // MARK: Private Properties

    @IBOutlet private var title: UILabel!
    
    // MARK: Actions
    
    @IBAction private func onTap(_ sender: Any?) {
        guard let linkMenuItemModel = linkMenuItemModel else { return }
        delegate?.didSelectLinkMenuItem(linkMenuItemModel)
    }
}
