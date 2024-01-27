//
//  TimeSegmentHourCollectionViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 9/12/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class TimeSegmentHourCollectionViewCell: UICollectionViewCell {

    // MARK: - Outlets
    @IBOutlet weak var timeLabel: UILabel! {
        didSet {
            timeLabel.font = AppConstants.Fonts.robotoRegular(12).font
        }
    }
    @IBOutlet weak var blockOutView: UIView!
    
    // MARK: - Properties
    var date: TimeSelectorDate? {
        didSet {
            let formatter = DateFormatter()
            formatter.amSymbol = "am"
            formatter.pmSymbol = "pm"
            formatter.dateFormat = "ha"
            timeLabel.text = formatter.string(from: date?.date ?? Date())
            setBlockOut(date?.isBlockOutDate ?? false)
        }
    }
    
    var isBlockOut: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        date = nil
        timeLabel.text = nil
        setBlockOut(false)
    }
    
    public func setBlockOut(_ blockOut: Bool) {
        blockOutView.isHidden = !blockOut
        timeLabel.textColor = blockOut ? .white : .black
    }
}
