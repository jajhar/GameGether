//
//  ScrollView+Extensions.swift
//  GameGether
//
//  Created by James Ajhar on 9/8/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

extension UIScrollView {
    
    /// Sets content offset to the top.
    func scrollToTop() {
        contentOffset = CGPoint(x: -contentInset.left, y: -contentInset.top)
    }
    
    func scrollToPage(page: Int, animated: Bool) {
        var frame: CGRect = bounds
        frame.origin.x = frame.size.width * CGFloat(page)
        frame.origin.y = 0
        scrollRectToVisible(frame, animated: animated)
    }
}
