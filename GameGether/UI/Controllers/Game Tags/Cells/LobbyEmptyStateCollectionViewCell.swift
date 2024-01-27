//
//  LobbyEmptyStateCollectionViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 7/1/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class LobbyEmptyStateCollectionViewCell: UICollectionViewCell {

    // MARK: Outlets
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = UIColor(hexString: "#BDBDBD")
            titleLabel.font = AppConstants.Fonts.robotoRegular(14).font
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
