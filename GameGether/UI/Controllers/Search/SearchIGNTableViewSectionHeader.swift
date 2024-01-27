//
//  SearchIGNTableViewSectionHeader.swift
//  GameGether
//
//  Created by James Ajhar on 8/25/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class SearchIGNTableViewSectionHeader: UIView {

    // MARK: Outlets
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.font = AppConstants.Fonts.robotoMedium(17).font
    }
}
