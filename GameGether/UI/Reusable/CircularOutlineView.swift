//
//  CircularOutlineView.swift
//  GameGether
//
//  Created by James Ajhar on 5/15/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class CircularOutlineView :UIView
{
    @IBInspectable var mainColor: UIColor = UIColor.blue {
        didSet { }
    }
    @IBInspectable var ringColor: UIColor = UIColor.orange
        {
        didSet { }
    }
    @IBInspectable var ringThickness: CGFloat = 4
        {
        didSet { }
    }
    
    @IBInspectable var isSelected: Bool = true
    
    override func draw(_ rect: CGRect)
    {
        let dotPath = UIBezierPath(ovalIn:rect)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = dotPath.cgPath
        shapeLayer.fillColor = mainColor.cgColor
        layer.addSublayer(shapeLayer)
        
        if (isSelected) { drawRingFittingInsideView(rect: rect) }
    }
    
    internal func drawRingFittingInsideView(rect: CGRect)->()
    {
        let hw:CGFloat = ringThickness/2
        let circlePath = UIBezierPath(ovalIn: rect.insetBy(dx: hw, dy: hw))
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = ringColor.cgColor
        shapeLayer.lineWidth = ringThickness
        layer.addSublayer(shapeLayer)
    }
}
