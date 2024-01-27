//
//  TimeSegmentHalfHourCollectionViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 9/12/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class TimeSegmentHalfHourCollectionViewCell: UICollectionViewCell {

    // MARK: - Properties
    var date: TimeSelectorDate? {
        didSet {
            setBlockOut(date?.isBlockOutDate ?? false)
        }
    }
    @IBOutlet weak var blockOutView: UIView!
    @IBOutlet weak var middleDividerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        date = nil
        setBlockOut(false)
    }
    
    private func setBlockOut(_ blockOut: Bool) {
        blockOutView.isHidden = !blockOut
        middleDividerView.backgroundColor = blockOut ? .white : .black
    }
}
