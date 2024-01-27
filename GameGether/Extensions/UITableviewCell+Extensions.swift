//
//  UITableviewCell+Extensions.swift
//  GameGether
//
//  Created by James Ajhar on 7/29/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

extension UITableViewCell {
    
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UICollectionViewCell {
    
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}
