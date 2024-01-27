//
//  AddFriendsViewController.swift
//  GameGether
//
//  Created by James Ajhar on 8/21/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD

class AddFriendsViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var gamerTagField: GamerTagSearchTextField! {
        didSet {
            gamerTagField.autocorrectionType = .no
            gamerTagField.placeholder = "type in gg username"
        }
    }
    
    @IBOutlet weak var searchUsersTableView: SearchUsersTableView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var infoLabel: UILabel!
    
    // MARK: Properties
    private(set) var selectedUser: User? {
        didSet {
            guard let selectedUser = selectedUser else {
                searchUsersTableView.selectedUsers.removeAll()
                return
            }
            searchUsersTableView.selectedUsers = [selectedUser]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        gamerTagField.searchDelegate = self
        
        hideKeyboardWhenBackgroundTapped()
        
        searchUsersTableView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        _ = gamerTagField.becomeFirstResponder()
    }
    
    private func performSearch() {
        
        selectedUser = nil
        sendButton.isEnabled = false
        infoLabel.isHidden = true
        searchUsersTableView.resetDataSource()
        
        guard let text = gamerTagField.text, !text.isEmpty else {
            return
        }
        
        let strings = text.components(separatedBy: "#")
        
        guard let ignToSearch = strings.first else { return }
        
        let ignCount = strings.last
        var ignCountToSearch: Int?
        
        if let count = ignCount {
            ignCountToSearch = Int(count)
        }
        
        searchUsersTableView.searchForUsers(withIGN: ignToSearch, andIGNCount: ignCountToSearch)
    }
    
    private func resetState() {
        searchUsersTableView.isHidden = true
        sendButton.isEnabled = false
        infoLabel.isHidden = true
        selectedUser = nil
    }

    // MARK: Interface Actions
    
    @IBAction func sendButtonPressed(_ sender: UIButton) {
        guard let selectedUser = selectedUser else { return }
        
        HUD.show(.progress)
        
        DataCoordinator.shared.addFriend(withUserId: selectedUser.identifier) { [weak self] (error, _) in
            performOnMainThread {
                
                HUD.hide()
                
                guard let strongself = self else { return }
                
                guard error == nil else {
                    strongself.presentGenericErrorAlert()
                    return
                }
                
                HUD.flash(.label("Friend request sent"), onView: strongself.view, delay: 0.5) { (finished) in
                    strongself.dismissSelf()
                }
            }
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        dismissSelf()
    }
    
    @IBAction func shareInviteLinkedPressed(_ sender: UIButton) {
        guard let user = DataCoordinator.shared.signedInUser else { return }
        let text = "yo! add me on GameGether! - your gamer friend \(user.ign)\nhttps://apps.apple.com/app/id1434236090"
        displayShareSheet(withText: text)
    }
    
    @IBAction func gamerTagFieldTextDidChange(_ sender: GamerTagSearchTextField) {
        guard let text = sender.text, !text.isEmpty else {
            searchUsersTableView.isHidden = true
            return
        }
        
        searchUsersTableView.isHidden = false
    }
}

extension AddFriendsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < searchUsersTableView.users.count else {
            return
        }
        
        let userToSelect = searchUsersTableView.users[indexPath.row]

        if selectedUser?.identifier == userToSelect.identifier {
            // Same user tapped twice, deselect the old user and stop
            selectedUser = nil
            sendButton.isEnabled = false
            infoLabel.isHidden = true
            return
            
        } else if selectedUser != nil {
            // deselect the old user
            selectedUser = nil
            sendButton.isEnabled = false
            infoLabel.isHidden = true
        }
        
        // Select the new user
        selectedUser = userToSelect
        sendButton.isEnabled = true
        infoLabel.isHidden = false
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let nib = UINib(nibName: SearchIGNTableViewSectionHeader.nibName, bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil).first as! SearchIGNTableViewSectionHeader
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 72
    }
}

extension AddFriendsViewController: GamerTagSearchTextFieldDelegate {
    
    func gamerTagSearchTextField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func gamerTagSearchTextField(textField: GamerTagSearchTextField, didUpdateText text: String?) {
       
        guard let text = text, !text.isEmpty else {
            resetState()
            return
        }
        
        performSearch()
    }
}
