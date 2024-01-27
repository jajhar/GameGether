//
//  String+Extensions.swift
//  GameGether
//
//  Created by James Ajhar on 6/23/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import UIKit

extension NSMutableAttributedString {
    
    @discardableResult
    func addLink(toText text: String, linkURL: String) -> Bool {
        
        let foundRange = self.mutableString.range(of: text)
        if foundRange.location != NSNotFound {
            self.addAttribute(.link, value: linkURL, range: foundRange)
            return true
        }
        return false
    }
    
    @discardableResult
    func addColor(color: UIColor, toText text: String) -> Bool {
        let foundRange = self.mutableString.range(of: text)
        if foundRange.location != NSNotFound {
            self.addAttributes([.foregroundColor: color], range: foundRange)
            return true
        }
        return false
    }
    
    var fullRange: NSRange {
        return (self.string as NSString).range(of: self.string)
    }
}

extension String {
    
    var isNumeric: Bool {
        return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: self))
    }
    
    func urlEncoded() -> String? {
        let unreserved = "-._~/"
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: unreserved)
        return addingPercentEncoding(withAllowedCharacters: allowed)
    }
}
