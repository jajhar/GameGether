//
//  LoadingTableViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 4/18/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class LoadingTableViewCell: UITableViewCell {

    private(set) var spinner: UIActivityIndicatorView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        spinner = contentView.displaySpinner()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
//        if let spinner = spinner {
//            contentView.removeSpinner(spinner: spinner)
//        }
    }
}
