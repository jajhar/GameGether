//
//  NewGameSessionCollectionViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 9/16/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class NewGameSessionCollectionViewCell: UICollectionViewCell {

    // MARK: - Outlets
    @IBOutlet weak var shadowView: UIView! {
        didSet {
            shadowView.addDropShadow(color: .black, opacity: 0.3, offset: CGSize(width: 2, height: 2), radius: 2)
        }
    }
    
    private var borderLayer: CAShapeLayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addBorderToView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutIfNeeded()
        borderLayer?.removeFromSuperlayer()
        addBorderToView()
    }
    
    private func addBorderToView() {
        let border = CAShapeLayer()
        border.strokeColor = UIColor(hexString: "#57A2E1").cgColor
        border.lineDashPattern = [2, 2]
        border.frame = contentView.bounds
        border.fillColor = nil
        border.path = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: 14).cgPath
        border.cornerRadius = 14
        
        borderLayer = border
        shadowView.layer.addSublayer(border)
    }
}
