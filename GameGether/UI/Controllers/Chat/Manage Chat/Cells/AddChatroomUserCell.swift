//
//  AddChatroomUserCell.swift
//  GameGether
//
//  Created by James Ajhar on 8/19/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class AddChatroomUserCell: UITableViewCell {

    // MARK: Outlets
    @IBOutlet weak var addFriendLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        addFriendLabel.font = AppConstants.Fonts.robotoMedium(14).font
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
