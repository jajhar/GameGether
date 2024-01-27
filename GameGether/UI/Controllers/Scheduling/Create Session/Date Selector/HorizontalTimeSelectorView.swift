//
//  HorizontalTimeSelectorView.swift
//  GameGether
//
//  Created by James Ajhar on 9/12/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

struct TimeSelectorDate {
    var date: Date
    var isBlockOutDate: Bool = false
}

class HorizontalTimeSelectorView: UICollectionView {
    
    struct Constants {
        static let cellWidth: CGFloat = 36
    }
    
    // MARK: - Properties
    private(set) var dates = [TimeSelectorDate]()
    
    /// True if the user initiated a date change via scrolling
    private(set) var userDidScroll: Bool = false

    private(set) var selectedDate: TimeSelectorDate = TimeSelectorDate(date: Date.now, isBlockOutDate: false) {
        didSet {
            onSelectedDateDidChange?(selectedDate)
        }
    }
    
    private var ignoreScrollDelegate: Bool = false
    
    var startDate: Date = Date.now {
        didSet {
            buildDataSource(fromStartDate: startDate)
        }
    }
    
    var blockoutDates = [Date]() {
        didSet {
            buildDataSource(fromStartDate: startDate)
        }
    }
    
    var initialDate: Date? {
        didSet {
            guard initialDate != nil else { return }
            buildDataSource(fromStartDate: startDate)
        }
    }
    
    var onSelectedDateDidChange: ((TimeSelectorDate) -> Void)?
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    internal func commonInit() {
        dataSource = self
        delegate = self
        showsHorizontalScrollIndicator = false
        
        register(UINib(nibName: TimeSegmentHourCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: TimeSegmentHourCollectionViewCell.reuseIdentifier)
        register(UINib(nibName: TimeSegmentHalfHourCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: TimeSegmentHalfHourCollectionViewCell.reuseIdentifier)
        
        (collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .horizontal
        
        buildDataSource(fromStartDate: startDate)        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let inset: CGFloat = (bounds.width / 2) - (Constants.cellWidth / 2)
        contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
    }
    
    public func selectDate(nearestTo dateToSelect: Date, animated: Bool = true) {
        var closest: Int?
        
        for (index, date) in dates.enumerated() {
            if dateToSelect <= date.date {
                closest = index
                break
            }
        }
        
        if let index = closest {
            let indexPath = IndexPath(item: index, section: 0)
            selectedDate = dates[index]
            ignoreScrollDelegate = true
            scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
        }
    }
    
    public func selectNextAvailableDate(animated: Bool = true) {
        
        // normalize the date first by removing minutes
        var date = selectedDate.date.subtractMinutes(selectedDate.date.minutes) ?? selectedDate.date
        
        while isBlockOutDate(date) {
            guard let newDate = date.addMinutes(30) else { break }
            date = newDate
        }
        
        selectDate(nearestTo: date, animated: animated)
    }
    
    private func selectClosestDate(scrollToDate: Bool = true, provideFeedback: Bool = true) {
        // Find collectionview cell nearest to the center of collectionView
        // Arbitrarily start with the first cell (as a default)
        guard var closestCell = visibleCells.first else { return }
        
        for cell in visibleCells {
            let closestCellDelta = abs(closestCell.center.x - bounds.size.width/2.0 - contentOffset.x)
            let cellDelta = abs(cell.center.x - (bounds.size.width / 2.0) - contentOffset.x)
            if (cellDelta < closestCellDelta){
                closestCell = cell
            }
        }
        guard let indexPath = indexPath(for: closestCell) else { return }
        
        let newDate = dates[indexPath.item]
        if provideFeedback, selectedDate.date != newDate.date {
            // New date selected. Provide haptic feedback
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
        
        selectedDate = newDate
        
        if scrollToDate {
            ignoreScrollDelegate = true
            scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
}

extension HorizontalTimeSelectorView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    private func buildDataSource(fromStartDate startDate: Date = Date.now) {

        dates.removeAll()
        var curHour = 0
        
        var roundedStartDate = startDate
            .subtractMinutes(startDate.minutes)?
            .subtractSeconds(startDate.seconds) ?? Date.now
        
        while roundedStartDate < startDate {
            roundedStartDate = roundedStartDate.addMinutes(30) ?? startDate
        }
    
        if Date.now.minutes(from: roundedStartDate) < 30 {
            // if the start date is less than 30 min from the current time, add another 30 minutes to it
            roundedStartDate = roundedStartDate.addMinutes(30) ?? roundedStartDate
        }
        
        var hourIndexRemainder = 0
        if roundedStartDate.minutes > 0 {
            // We're starting with a half-hour time block.
            hourIndexRemainder = 1
            roundedStartDate = roundedStartDate.subtractMinutes(30) ?? roundedStartDate
        }
        
        let maxDays: Int = 48 * 120 // 120 days worth of dates
        
        for index in 0..<maxDays {
            if index % 2 == hourIndexRemainder {
                // hour
                let date = roundedStartDate.addHours(curHour) ?? Date()
                dates.append(TimeSelectorDate(date: date, isBlockOutDate: isBlockOutDate(date)))
            } else {
                // half hour
                let date = roundedStartDate.addHours(curHour)?.addMinutes(30) ?? Date()
                dates.append(TimeSelectorDate(date: date, isBlockOutDate: isBlockOutDate(date)))
                curHour += 1
            }
        }

        reloadData()
    
        // Refresh the current selected date since its blockout status may have changed
        selectedDate = TimeSelectorDate(date: initialDate ?? selectedDate.date,
                                        isBlockOutDate: isBlockOutDate(initialDate ?? selectedDate.date))
        selectNextAvailableDate()
        initialDate = nil
    }
    
    public func isBlockOutDate(_ date: Date) -> Bool {
        // Date is in the past
        guard date >= Date.now else { return true }
        
        for blockoutDate in blockoutDates {
            // Remove the nano seconds from both dates for EXACT matching
            let normalizedBlockoutDate = blockoutDate.subtractNanoseconds(blockoutDate.nanoseconds) ?? blockoutDate
            let normalizedDate = date.subtractNanoseconds(date.nanoseconds) ?? date
            
            if (normalizedDate >= normalizedBlockoutDate && normalizedDate < normalizedBlockoutDate.addHours(1) ?? normalizedBlockoutDate) ||
                (normalizedDate <= normalizedBlockoutDate && normalizedDate > normalizedBlockoutDate.subtractHours(1) ?? normalizedBlockoutDate) {
                return true
            }
        }
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dates.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let date = dates[indexPath.item]

        if date.date.minutes == 0 {
            // hour
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TimeSegmentHourCollectionViewCell.reuseIdentifier, for: indexPath) as! TimeSegmentHourCollectionViewCell
            cell.date = date
            return cell
        }
        
        // half hour
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TimeSegmentHalfHourCollectionViewCell.reuseIdentifier, for: indexPath) as! TimeSegmentHalfHourCollectionViewCell
        cell.date = date
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Constants.cellWidth, height: bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let date = dates[indexPath.item]
        selectedDate = date
        ignoreScrollDelegate = true
        scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}

extension HorizontalTimeSelectorView {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !ignoreScrollDelegate else { return }
        selectClosestDate(scrollToDate: false)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        ignoreScrollDelegate = false
        userDidScroll = true
        initialDate = nil
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !ignoreScrollDelegate, !decelerate else { return }
        selectClosestDate()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard !ignoreScrollDelegate else { return }
        selectClosestDate()
    }
}
