//
//  SessionTypesTableView.swift
//  GameGether
//
//  Created by James Ajhar on 10/1/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD

class SessionTypesTableView: UITableView {

   // MARK: - Properties
    
    var game: Game? {
        didSet {
            reloadDataSource()
        }
    }
    
    var onTypeSelected: ((GameSessionType) -> Void)?
    
    var typeToSelect: GameSessionTypeIdentifier? {
    didSet {
            guard let rawType = typeToSelect,
                let type = sessionTypes.filter({ $0.type == rawType }).first else { return }
            selectedSessionType = type
        }
    }
    
    var associatedTagToSelect: Tag? {
        didSet {
            guard let tag = associatedTagToSelect,
                let type = sessionTypes.filter({ $0.associatedTags.contains(where: { $0.identifier == tag.identifier })}).first else { return }
            selectedSessionType = type
        }
    }
    
    private(set) var selectedSessionType: GameSessionType? {
        didSet {
            if let type = selectedSessionType {
                onTypeSelected?(type)
            }
            reloadData()
        }
    }
    
    private(set) var sessionTypes = [GameSessionType]() {
        didSet {
            if let tag = associatedTagToSelect,
                let type = sessionTypes.filter({ $0.associatedTags.contains(where: { $0.identifier == tag.identifier })}).first {
                selectedSessionType = type
                associatedTagToSelect = nil
                
            } else if let rawType = typeToSelect {
                let type = sessionTypes.filter({ $0.type == rawType }).first
                selectedSessionType = type
                typeToSelect = nil
            }
            
            reloadData()
        }
    }
    
    public func reloadDataSource() {
        guard let game = game else { return }
        
        HUD.show(.progress)
        
        DataCoordinator.shared.getGameSessionTypes(forGame: game.identifier) { [weak self] (types, error) in
            
            performOnMainThread {
                HUD.hide()
            }
            
            guard error == nil else {
                GGLog.error(error?.localizedDescription ?? "unknown error")
                return
            }
            performOnMainThread {
                self?.sessionTypes = types
                self?.selectedSessionType = self?.selectedSessionType ?? types.first
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
        register(SessionTypeTableViewCell.self, forCellReuseIdentifier: SessionTypeTableViewCell.reuseIdentifier)
        rowHeight = 38.0
    }
}

extension SessionTypesTableView: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessionTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SessionTypeTableViewCell.reuseIdentifier) as! SessionTypeTableViewCell
        let type = sessionTypes[indexPath.row]
        cell.sessionType = type
        
        cell.setIsSelected(type.identifier == selectedSessionType?.identifier)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // auto-deselect the cell because we manage selection via a separate var
        tableView.deselectRow(at: indexPath, animated: false)

        let type = sessionTypes[indexPath.row]
        selectedSessionType = type
    }
}

private class SessionTypeTableViewCell: UITableViewCell {
    
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
    
    let typeLabel: UILabel = {
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
    
    var sessionType: GameSessionType? {
        didSet {
            setupWithType()
        }
    }
    
    private var isTypeSelected: Bool = false
    
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
        contentView.addSubview(typeLabel)
        typeLabel.constrainToSuperview()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        typeLabel.text = nil
        setIsSelected(false)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setIsSelected(isTypeSelected)
    }
    
    private func setupWithType() {
        guard let type = sessionType else { return }
        typeLabel.text = type.title
    }
    
    public func setIsSelected(_ selected: Bool) {
        typeLabel.font = selected ? AppConstants.Fonts.robotoMedium(16).font : AppConstants.Fonts.robotoLight(16).font
        isTypeSelected = selected
        borderView.isHidden = !selected
    }
}
