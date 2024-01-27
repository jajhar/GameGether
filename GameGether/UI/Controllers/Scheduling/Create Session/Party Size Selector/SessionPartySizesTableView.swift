//
//  SessionPartySizesTableView.swift
//  GameGether
//
//  Created by James Ajhar on 10/3/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD

class SessionPartySizesTableView: UITableView {

   // MARK: - Properties
    
    var game: Game? {
        didSet {
            reloadDataSource()
        }
    }
    
    private(set) var selectedSize: Tag? {
        didSet { reloadData() }
    }

    private(set) var partySizes = [Tag]() {
        didSet { reloadData() }
    }
    
    var onSizeSelected: ((Tag) -> Void)?

    public func reloadDataSource() {
        guard let game = game else { return }
        
        HUD.show(.progress)
                
        DataCoordinator.shared.getTags(forGame: game.identifier) { [weak self] (remoteTags, error) in
            
            performOnMainThread {
                HUD.hide()
            }
            
            guard let weakSelf = self, error == nil, let remoteTags = remoteTags else {
                GGLog.error("Error: \(String(describing: error))")
                return
            }
            
            performOnMainThread {
                var sizeTags = remoteTags.sizeTags()
                sizeTags.sortByPriority()
                weakSelf.partySizes = sizeTags
            }
        }
    }
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        dataSource = self
        delegate = self
        separatorStyle = .none
        register(SessionPartySizeTableViewCell.self, forCellReuseIdentifier: SessionPartySizeTableViewCell.reuseIdentifier)
        rowHeight = 38.0
    }
}

extension SessionPartySizesTableView: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return partySizes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SessionPartySizeTableViewCell.reuseIdentifier) as! SessionPartySizeTableViewCell
        let tag = partySizes[indexPath.row]
        cell.sizeTag = tag
        
        cell.setIsSelected(tag.identifier == selectedSize?.identifier)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // auto-deselect the cell because we manage selection via a separate var
        tableView.deselectRow(at: indexPath, animated: false)

        let tag = partySizes[indexPath.row]
        selectedSize = tag
        onSizeSelected?(tag)
    }
}

private class SessionPartySizeTableViewCell: UITableViewCell {
    
    private class SelectedBorderView: UIView {
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addBorder()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            addBorder()
        }
        
        private func addBorder() {
            layer.sublayers?.forEach({ $0.removeFromSuperlayer() })
            layer.addBorder(edge: .top, color: UIColor(hexString: "#DDDDDD"), thickness: 1.5)
            layer.addBorder(edge: .bottom, color: UIColor(hexString: "#DDDDDD"), thickness: 1.5)
        }
    }
    
    let sizeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let borderView: SelectedBorderView = {
        let view = SelectedBorderView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var sizeTag: Tag? {
        didSet {
            setupWithSize()
        }
    }
    
    private var isSizeSelected: Bool = false
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        contentView.addSubview(borderView)
        borderView.constrainToSuperview()
        contentView.addSubview(sizeLabel)
        sizeLabel.constrainToSuperview()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        sizeLabel.text = nil
        setIsSelected(false)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setIsSelected(isSizeSelected)
    }
    
    private func setupWithSize() {
        guard let tag = sizeTag else { return }
        sizeLabel.text = "\(tag.size)"
    }
    
    public func setIsSelected(_ selected: Bool) {
        sizeLabel.font = selected ? AppConstants.Fonts.robotoMedium(16).font : AppConstants.Fonts.robotoLight(16).font
        isSizeSelected = selected
        borderView.isHidden = !selected
    }
}
