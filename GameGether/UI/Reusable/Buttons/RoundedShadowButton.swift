//
//  RoundedShadowButton.swift
//  GameGether
//
//  Created by James Ajhar on 8/12/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

extension UIButton {
    
    func addRoundedDropShadow(color: UIColor, opacity: Float = 0.5, fillColor: UIColor, offset: CGSize = .zero, radius: CGFloat = 1, cornerRadius: CGFloat) {
        let shadowLayer = CAShapeLayer()
        shadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        shadowLayer.fillColor = fillColor.cgColor
        shadowLayer.shadowColor = color.cgColor
        shadowLayer.shadowPath = shadowLayer.path
        shadowLayer.shadowOffset = offset
        shadowLayer.shadowOpacity = opacity
        shadowLayer.shadowRadius = radius
        layer.insertSublayer(shadowLayer, at: 0)
    }
}
