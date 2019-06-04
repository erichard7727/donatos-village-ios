//
//  RecentActivityCollectionViewLayout.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 10/20/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit



class RecentActivityCollectionViewLayout: UICollectionViewFlowLayout {
    let cellWidth: CGFloat = 340
    let cellHeight: CGFloat = 110
    var layoutInfo: [NSIndexPath:UICollectionViewLayoutAttributes] = [NSIndexPath:UICollectionViewLayoutAttributes]()
    var maxXPos: CGFloat = 0
    
    override init() {
        super.init()
        setValues()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setValues()
    }
    
    func setValues() {
        self.itemSize = CGSize(width: cellWidth, height: cellHeight)
        self.scrollDirection = UICollectionView.ScrollDirection.vertical
    }
    
    override func prepare() {
        layoutInfo = [NSIndexPath:UICollectionViewLayoutAttributes]()
        
        var indexPath: NSIndexPath
        
        guard let numItems = collectionView?.numberOfItems(inSection: 0) else {
            return
        }
        
        if numItems == 0 {
            return
        }
        
        for item in 1...numItems {
            indexPath = NSIndexPath(row: item, section: 0)
            let itemAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath as IndexPath)
            layoutInfo[indexPath] = itemAttributes
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        //change z index for cascading effect
        let attributes = super.layoutAttributesForElements(in: rect)
        attributes?.forEach {
            if ($0.indexPath.row == 0) {
                $0.zIndex = Int(INT_MAX)
            } else {
                $0.zIndex = 100 - $0.indexPath.row;
            }
        }
        return attributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItem(at: indexPath)
        
        if (indexPath.row == 0) {
            attributes?.zIndex = Int(INT_MAX)
        } else {
            attributes?.zIndex = 100 - indexPath.row;
        }
        
        return attributes
    }
    
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let layoutAttributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
        return layoutAttributes
    }
}
