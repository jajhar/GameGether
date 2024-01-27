//
//  GGCalendarView.swift
//  GameGether
//
//  Created by James Ajhar on 9/10/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import JTAppleCalendar

class GGCalendarView: UIView {
    
    let weekdayHeader: UIStackView = {
        let view = UIStackView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.distribution = .fillEqually
        
        for i in 0..<7 {
            let label = UILabel(frame: .zero)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.font = AppConstants.Fonts.robotoBold(18).font
            
            switch i {
            case 0:
                label.text = "S"
            case 1:
                label.text = "M"
            case 2:
                label.text = "T"
            case 3:
                label.text = "W"
            case 4:
                label.text = "T"
            case 5:
                label.text = "F"
            case 6:
                label.text = "S"
            default:
                break
            }
            
            view.addArrangedSubview(label)
        }
        return view
    }()
    
    private let collectionView: JTAppleCalendarView = {
        let collectionView: JTAppleCalendarView = JTAppleCalendarView(frame: .zero)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(GGDateCell.self, forCellWithReuseIdentifier: GGDateCell.reuseIdentifier)
        collectionView.register(GGDateHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "\(GGDateHeader.self)")
        collectionView.backgroundColor = .white
        collectionView.allowsSelection = true
        collectionView.cellSize = 50
        return collectionView
    }()
    
    var onDateSelected: ((Date) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        
        addSubview(weekdayHeader)
        weekdayHeader.constrainTo(edges: .left, .top, .right)
        weekdayHeader.constrainHeight(40)
        
        addSubview(collectionView)
        collectionView.constrainTo(edges: .left, .bottom, .right)
        collectionView.constrain(attribute: .top, toItem: weekdayHeader, attribute: .bottom)
        collectionView.ibCalendarDelegate = self
        collectionView.ibCalendarDataSource = self
    }
    
    public func deselectAllDates() {
        collectionView.deselectAllDates()
        collectionView.reloadData()
    }
    
    public func selectDate(_ date: Date) {
        collectionView.selectDates([date])
        collectionView.reloadData()
    }
}

extension GGCalendarView: JTAppleCalendarViewDataSource {
    
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MM dd"
        let startDate = Date.now
        let endDate = Date.now.addDays(120) ?? Date()
        return ConfigurationParameters(startDate: startDate, endDate: endDate)
    }
}

extension GGCalendarView: JTAppleCalendarViewDelegate {
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: GGDateCell.reuseIdentifier, for: indexPath) as! GGDateCell
        self.calendar(calendar, willDisplay: cell, forItemAt: date, cellState: cellState, indexPath: indexPath)
        return cell
    }
    
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        configureCell(cell, cellState: cellState)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        collectionView.reloadData()
        onDateSelected?(date)
    }
    
    func configureCell(_ cell: JTAppleCell?, cellState: CellState) {
        guard let cell = cell as? GGDateCell else { return }
        cell.dateLabel.text = cellState.text
        cell.isHidden = cellState.dateBelongsTo != .thisMonth
        
        cell.setSelected(cellState.isSelected)

        if cellState.date >= Date.today, cellState.date <= Date.now.addDays(120) ?? Date.distantFuture{
            cell.dateLabel.alpha = 1
        } else {
            cell.dateLabel.alpha = 0.5
        }
    }
    
    func calendar(_ calendar: JTAppleCalendarView, shouldSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) -> Bool {
        return date >= Date.today
    }
    
    func calendar(_ calendar: JTAppleCalendarView, headerViewForDateRange range: (start: Date, end: Date), at indexPath: IndexPath) -> JTAppleCollectionReusableView {
        let formatter = DateFormatter()  // Declare this outside, to avoid instancing this heavy class multiple times.
        formatter.dateFormat = "MMMM"
    
        let header = calendar.dequeueReusableJTAppleSupplementaryView(withReuseIdentifier: "\(GGDateHeader.self)", for: indexPath) as! GGDateHeader
        header.monthLabel.text = formatter.string(from: range.start)
        return header
    }
    
    func calendarSizeForMonths(_ calendar: JTAppleCalendarView?) -> MonthSize? {
        return MonthSize(defaultSize: 40)
    }
}

class GGDateCell: JTAppleCell {
    
    let dateLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = AppConstants.Fonts.robotoMedium(16).font
        return label
    }()
    
    let selectionView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hexString: "#1C6EB9")
        view.constrainWidth(50)
        view.constrainHeight(50)
        view.cornerRadius = 25
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        contentView.addSubview(selectionView)
        selectionView.constrainToCenter()
        
        contentView.addSubview(dateLabel)
        dateLabel.constrainToSuperview()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        dateLabel.text = nil
        setSelected(false)
        isHidden = false
    }
    
    func setSelected(_ selected: Bool) {
        selectionView.isHidden = !selected
        dateLabel.textColor = selected ? .white : .black
    }
}

class GGDateHeader: JTAppleCollectionReusableView {
    
    let monthLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = AppConstants.Fonts.robotoBold(18).font
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        addSubview(monthLabel)
        monthLabel.constrainToSuperview()
    }
}
