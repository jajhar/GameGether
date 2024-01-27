//
//  Numbers+Extensions.swift
//  GameGether
//
//  Created by James Ajhar on 2/13/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import Foundation
import UIKit

extension BinaryInteger {
    var degreesToRadians: CGFloat { return CGFloat(Int(self)) * .pi / 180 }
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}
