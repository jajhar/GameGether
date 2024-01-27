//
//  UIView+Extension.swift
//  App
//
//  Created by James on 4/26/18.
//  Copyright © 2018 James. All rights reserved.
//

import UIKit

public enum AutoLayoutEdge {
    case top
    case bottom
    case left
    case right
}

public extension UIView {
    
    func constrainTo(edges: AutoLayoutEdge...) {
        for edge in edges {
            _ = constrainTo(edge: edge)
        }
    }
    
    @discardableResult
    func constrainTo(edge: AutoLayoutEdge) -> NSLayoutConstraint? {
        guard let superview = self.superview else {
            return nil
        }
        
        var constraint: NSLayoutConstraint?
        
        switch edge {
        case .top:
            constraint = topAnchor.constraint(equalTo: superview.topAnchor)
        case .bottom:
            constraint = bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        case .left:
            constraint = leadingAnchor.constraint(equalTo: superview.leadingAnchor)
        case .right:
            constraint = trailingAnchor.constraint(equalTo: superview.trailingAnchor)
        }
        
        constraint?.isActive = true
        return constraint
    }
    
    func constrainToSuperview() {
        constrainTo(edges: .top, .bottom, .left, .right)
    }
    
    @discardableResult
    func constrainWidth(_ width: CGFloat, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        let widthConstraint = NSLayoutConstraint(item: self,
                                                 attribute: .width,
                                                 relatedBy: relation,
                                                 toItem: nil,
                                                 attribute: .notAnAttribute,
                                                 multiplier: 1,
                                                 constant: width)
        addConstraint(widthConstraint)
        widthConstraint.isActive = true
        return widthConstraint
    }
    
    @discardableResult
    func constrainHeight(_ height: CGFloat, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        let heightConstraint = NSLayoutConstraint(item: self,
                                                  attribute: .height,
                                                  relatedBy: relation,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1,
                                                  constant: height)
        addConstraint(heightConstraint)
        heightConstraint.isActive = true
        return heightConstraint
    }
    
    @discardableResult
    func constrain(attribute: NSLayoutConstraint.Attribute,
                   toItem item: Any,
                   attribute itemAttribute: NSLayoutConstraint.Attribute,
                   relation: NSLayoutConstraint.Relation = .equal,
                   constant: CGFloat = 0) -> NSLayoutConstraint? {
        
        guard let superview = self.superview else {
            return nil
        }
        
        let constraint = NSLayoutConstraint(item: self,
                                                  attribute: attribute,
                                                  relatedBy: relation,
                                                  toItem: item,
                                                  attribute: itemAttribute,
                                                  multiplier: 1,
                                                  constant: constant)
        superview.addConstraint(constraint)
        constraint.isActive = true
        return constraint
    }

    
    func constrainToCenter() {
        guard let superview = superview else { return }
        
        centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
        centerYAnchor.constraint(equalTo: superview.centerYAnchor).isActive = true
    }
    
    @discardableResult
    func constrainToCenterHorizontal() -> NSLayoutConstraint? {
        guard let superview = superview else { return nil }
        
        let constraint = centerXAnchor.constraint(equalTo: superview.centerXAnchor)
        constraint.isActive = true
        return constraint
    }
    
    @discardableResult
    func constrainToCenterVertical() -> NSLayoutConstraint? {
        guard let superview = superview else { return nil }
        
        let constraint =  centerYAnchor.constraint(equalTo: superview.centerYAnchor)
        constraint.isActive = true
        return constraint
    }

    class func instanceFromNib() -> UIView? {
        return UINib(nibName: "\(self)", bundle: Bundle(for: self)).instantiate(withOwner: nil, options: nil).first as? UIView
    }
}

extension UIView {
    
    static var nibName: String {
        return String(describing: self)
    }
    
    func addDropShadow(color: UIColor, opacity: Float = 0.5, offset: CGSize = .zero, radius: CGFloat = 1, scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

extension UIView {
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }
    
    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable
    var masksToBounds: Bool {
        get {
            return layer.masksToBounds
        }
        set {
            layer.masksToBounds = newValue
        }
    }
    
    @IBInspectable
    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable
    var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable
    var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
            } else {
                layer.shadowColor = nil
            }
        }
    }
}


extension UIView {
    
    func shake(count: Float = 2, for duration: TimeInterval = 0.3, withTranslation translation: Float = 5) {
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.repeatCount = count
        animation.duration = duration / TimeInterval(animation.repeatCount)
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: CGFloat(-translation), y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: CGFloat(translation), y: self.center.y))
        layer.add(animation, forKey: "shake")
    }
    
    func addHoverAnimation(duration: CFTimeInterval, distance: CGFloat, repeatCount: Float = Float.infinity) {
        let hover = CABasicAnimation(keyPath: "position")
        hover.isAdditive = true
        hover.fromValue = NSValue(cgPoint: CGPoint.zero)
        hover.toValue = NSValue(cgPoint: CGPoint(x: 0.0, y: distance))
        hover.autoreverses = true
        hover.duration = duration
        hover.repeatCount = repeatCount
        layer.add(hover, forKey: "myHoverAnimation")
    }
    
    func rotate(duration: CFTimeInterval, repeatCount: Float = Float.infinity) {
        let fullRotation = CABasicAnimation(keyPath: "transform.rotation")
        fullRotation.fromValue = 0.0
        fullRotation.toValue = CGFloat(.pi * 2.0)
        fullRotation.duration = duration
        fullRotation.repeatCount = repeatCount
        layer.add(fullRotation, forKey: "360_rotation")
    }
    
    func removeHoverAnimation() {
        layer.removeAnimation(forKey: "myHoverAnimation")
    }
    
    func fadeTransition(_ duration: CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.fade
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
}

extension UIView {
    
    var firstResponder: UIView? {
        guard !isFirstResponder else { return self }
        
        for subview in subviews {
            if let firstResponder = subview.firstResponder {
                return firstResponder
            }
        }
        
        return nil
    }
}

extension CALayer {

  func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat) {

    let border = CALayer()

    switch edge {
    case UIRectEdge.top:
        border.frame = CGRect(x: 0, y: 0, width: frame.width, height: thickness)

    case UIRectEdge.bottom:
        border.frame = CGRect(x:0, y: frame.height - thickness, width: frame.width, height:thickness)

    case UIRectEdge.left:
        border.frame = CGRect(x:0, y:0, width: thickness, height: frame.height)

    case UIRectEdge.right:
        border.frame = CGRect(x: frame.width - thickness, y: 0, width: thickness, height: frame.height)

    default:
        break
    }

    border.backgroundColor = color.cgColor

    addSublayer(border)
 }
}
