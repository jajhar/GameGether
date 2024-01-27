//
//  UserStatusImageView.swift
//  GameGether
//
//  Created by James Ajhar on 8/9/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class UserStatusImageView: UIImageView {

    // MARK: Properties
    var status: UserStatus? {
        didSet {
            updateStatus()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        contentMode = .scaleAspectFit
    }
    
    private func updateStatus() {
        guard let status = status else { return }
        
        switch status {
        case .online:
            image = #imageLiteral(resourceName: "Online")
        case .away:
            image = #imageLiteral(resourceName: "Away")
        case .offline:
            image = #imageLiteral(resourceName: "Offline")
        }
    }
}
