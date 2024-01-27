//
//  PartyTableView.swift
//  GameGether
//
//  Created by James Ajhar on 10/28/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

protocol PartyTableViewDelegate: class {
    func partyTableView(tableView: PartyTableView, canJoinParty party: FRParty) -> Bool
    func partyTableView(tableView: PartyTableView, didJoinParty party: FRParty)
    func partyTableView(tableView: PartyTableView, didLeaveParty party: FRParty)
    func partyTableView(tableView: PartyTableView, partiesDidUpdate parties: [FRParty])
}

class PartyTableView: UITableView {

    struct Constants {
        static let rowHeight: CGFloat = 68
    }
    
    /// An enum for filtering visible parties
    ///
    /// - all: ALL available parties
    /// - joined: Only parties that the logged in user has joined or created
    /// - unjoined: Only parties that DO NOT contain the logged in user
    enum PartyTableViewFilter {
        case all
        case joined
        case unjoined
    }
    
    // MARK: Properties
    private var tagsPartyData: [String: [FRParty]] = [:] {
        didSet {
            reloadWithAnimation()
        }
    }
    
    private var observedTags = [Tag]()
    
    var filter: PartyTableViewFilter = .all {
        didSet {
            reloadData()
        }
    }
    
    var parties: [FRParty] {
        var values = [FRParty]()
        for (key, value) in tagsPartyData {
            
            // Make sure all parties being shown contain the observed tags. IGNORE ALL SIZE TAGS!
            if key != observedTags.filter({ $0.size == 0 }).hashedValue { continue }
            
            switch filter {
            case .all:
                values.append(contentsOf: value)
            case .joined:
                values.append(contentsOf: value.filter({ $0.containsLoggedInUser }))
            case .unjoined:
                values.append(contentsOf: value.filter({ !$0.containsLoggedInUser }))
            }
        }
        return values
    }
    
    private let firebaseParty = FirebaseParty()
    private let firebaseChat = FirebaseChat()

    weak var partyTableViewDelegate: PartyTableViewDelegate?
    
    var maxVisibleRows: Int = 1 {
        didSet {
            reloadData()
        }
    }
    
    var contentHeight: CGFloat {
        guard parties.count > 0 else { return 0 }
        
        let verticalInsets = contentInset.top + contentInset.bottom
        let height = (CGFloat(parties.count) * Constants.rowHeight) + verticalInsets
        let maxHeight = (CGFloat(maxVisibleRows) * rowHeight) + verticalInsets
        return height <= maxHeight ? height : maxHeight
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
        firebaseParty.signIn()
        firebaseChat.signIn()
        dataSource = self
        delegate = self
        separatorStyle = .none
        allowsSelection = true
        register(UINib(nibName: "\(PartyTableViewCell.self)", bundle: nil),
                 forCellReuseIdentifier: PartyTableViewCell.reuseIdentifier)
        rowHeight = Constants.rowHeight
        contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func observeGame(_ game: Game, withTags tags: [Tag]) {
        tagsPartyData.removeAll()
        observedTags = tags
        
        reloadWithAnimation()
        
        firebaseParty.observeParties(forGame: game.identifier) { [weak self] (newParties) in
            guard let strongSelf = self else { return }

            performOnMainThread {
                
                strongSelf.tagsPartyData.removeAll()
                
                if let newParties = newParties {
                    for party in newParties {
                        // IGNORE ALL SIZE TAGS!
                        let hash = party.tags.filter({ $0.size == 0 }).hashedValue
                        var mutableCopy = strongSelf.tagsPartyData[hash] ?? []
                        mutableCopy.append(party)
                        strongSelf.tagsPartyData[hash] = mutableCopy
                    }
                }
                
                strongSelf.partyTableViewDelegate?.partyTableView(tableView: strongSelf, partiesDidUpdate: strongSelf.parties)
            }
        }
    }
    
    private func leaveParty(_ party: FRParty) {
        
        AnalyticsManager.track(event: .leftParty, withParameters: [
            "user": DataCoordinator.shared.signedInUser?.identifier ?? "",
            "party": party.identifier ?? ""
            ])
        
        firebaseParty.leaveParty(party) { [weak self] (error) in
            guard let strongSelf = self else { return }
            if let error = error {
                GGLog.error("\(error.localizedDescription)")
                return
            }
            strongSelf.partyTableViewDelegate?.partyTableView(tableView: strongSelf, didLeaveParty: party)
        }
    }
    
    private func reloadWithAnimation() {
        UIView.transition(with: self,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: { self.reloadData() })
    }
    
    private func joinParty(_ party: FRParty) {
        if let partyDelegate = partyTableViewDelegate, partyDelegate.partyTableView(tableView: self, canJoinParty: party) == false {
            // Can't join this party. Stop here.
            return
        }
        
        FirebasePartyManager.shared.joinParty(party) { [weak self] (joinedParty, error) in
            guard let weakSelf = self else { return }
            guard error == nil, let joinedParty = joinedParty else {
                GGLog.error("\(error?.localizedDescription ?? "")")
                return
            }
            
            performOnMainThread {
                weakSelf.partyTableViewDelegate?.partyTableView(tableView: weakSelf, didJoinParty: joinedParty)
            }
        }
    }
}

extension PartyTableView: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.isScrollEnabled = parties.count > 1
        return parties.count > maxVisibleRows ? maxVisibleRows : parties.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PartyTableViewCell.reuseIdentifier, for: indexPath) as! PartyTableViewCell
        cell.selectionStyle = .none
        cell.party = parties[indexPath.row]
        
        cell.onLeavePartyButtonTapped = { [weak self] (party) in
            self?.leaveParty(party)
        }
        
        cell.onJoinPartyButtonTapped = { [weak self] (party) in
            guard let weakSelf = self else { return }
            if let partyDelegate = weakSelf.partyTableViewDelegate, partyDelegate.partyTableView(tableView: weakSelf, canJoinParty: party) == false {
                // Can't join this party. Stop here.
                cell.togglePartyButton(selected: false)
                return
            }
            weakSelf.joinParty(party)
        }
        
        return cell
    }
}
