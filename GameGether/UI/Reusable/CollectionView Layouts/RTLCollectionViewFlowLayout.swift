//
//  RTLCollectionViewFlowLayout.swift
//  GameGether
//
//  Created by James Ajhar on 4/1/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class RTLCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override var flipsHorizontallyInOppositeLayoutDirection: Bool {
        return true
    }
    
    override var developmentLayoutDirection: UIUserInterfaceLayoutDirection {
        return UIUserInterfaceLayoutDirection.rightToLeft
    }
}

