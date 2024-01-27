//
//  NewMessageViewController.swift
//  GameGether
//
//  Created by James Ajhar on 8/14/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD

class NewMessageViewController: UIViewController {

    enum NewMessageSearchState {
        case friends
        case all
    }
    
    // MARK: Outlets
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var friendsTableView: FriendsTableView!
    @IBOutlet weak var messagesTableView: MessagesTableView!
    @IBOutlet weak var searchUsersTableView: SearchUsersTableView!
    @IBOutlet weak var searchImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addUserButton: UIButton!
    @IBOutlet weak var friendsTabButton: UIButton!
    @IBOutlet weak var allTabButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    // MARK: Properties
    let firebaseChat = FirebaseChat()
    var chatroom: FRChatroom?
    var game: Game?

    private var searchState: NewMessageSearchState = .all
    private(set) var selectedUserRanges: [Range<String.Index>] = [Range<String.Index>]()
    private(set) var selectedUsers: [User] = [User]() {
        didSet {
            searchUsersTableView.selectedUsers = selectedUsers
        }
    }
    
    public var onChatroomCreation: ((NewMessageViewController, FRChatroom) -> Void)?
    public var onChatroomEdited: ((NewMessageViewController, FRChatroom) -> Void)?
    
    /// Optional users to pre-populate the search field with (set externally)
    public var initialUsersToPopulate = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        styleUI()
        
        inputTextField.delegate = self
        friendsTableView.delegate = self
        friendsTableView.friendsTableViewDelegate = self
        searchUsersTableView.delegate = self
        
        setSearchState(newState: .all)

        firebaseChat.signIn()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        
        titleLabel.text = "Create A Group"
        
        // Add any prepopulated users to the list of selected users
        selectedUsers.append(contentsOf: initialUsersToPopulate)
        updateView()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func styleUI() {
        titleLabel.font = AppConstants.Fonts.robotoBold(16).font
        cancelButton.titleLabel?.font = AppConstants.Fonts.robotoBold(16).font
        addUserButton.titleLabel?.font = AppConstants.Fonts.robotoBold(16).font
        friendsTabButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(14).font
        allTabButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(14).font
        inputTextField.font = AppConstants.Fonts.robotoLight(14).font
    }
    
    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo else { return }
        
        let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
        
        UIView.animate(withDuration: duration,
                       delay: TimeInterval(0),
                       options: animationCurve,
                       animations: { self.view.layoutIfNeeded() },
                       completion: nil)
    }
    
    private func updateView() {
        
//        messagesTableView.isHidden = true
        selectedUserRanges.removeAll()
        
        let text = NSMutableAttributedString(string: "")
        for selectedUser in selectedUsers {
            let appendedText = selectedUser.fullIGNText
            appendedText.append(NSAttributedString(string: ", "))
            let curEndIndex = text.string.endIndex
            text.append(appendedText)
            let range = curEndIndex..<text.string.endIndex
            selectedUserRanges.append(range)
        }
        
        if !inputTextField.isFirstResponder {
            text.append(NSAttributedString(string: "type to search", attributes: [.foregroundColor: UIColor.lightGray]))
        }
        
        inputTextField.attributedText = text
        
//        if selectedUsers.count > 0, chatroom == nil {
//            let userIds = selectedUsers.compactMap({ $0.identifier })
//            firebaseChat.getChatroom(withUserIds: userIds) { [weak self] (existingChatroom) in
//                guard let strongself = self else { return }
//                performOnMainThread {
//                    if let chatroom = existingChatroom {
//                        strongself.messagesTableView.isHidden = false
//                        strongself.messagesTableView.chatroom = chatroom
//                    } else {
//                        strongself.messagesTableView.isHidden = true
//                    }
//                }
//            }
//        }
    }
    
    private func setSearchState(newState: NewMessageSearchState) {
        searchState = newState
        
        switch newState {
        case .friends:
            friendsTabButton.backgroundColor = AppConstants.Colors.newMessageTabButtonSelected.color
            allTabButton.backgroundColor = AppConstants.Colors.newMessageTabButtonUnselected.color
            friendsTableView.isHidden = false
            searchUsersTableView.isHidden = true
        case .all:
            allTabButton.backgroundColor = AppConstants.Colors.newMessageTabButtonSelected.color
            friendsTabButton.backgroundColor = AppConstants.Colors.newMessageTabButtonUnselected.color
            friendsTableView.isHidden = true
            searchUsersTableView.isHidden = false
        }
    }
    
    private func filterByOverlappingRanges(inText text: String, withRange range: NSRange) -> Bool {
        
        guard let convertedRange = Range(range, in: text) else { return false }
        var users = [User]()
        var ranges = [Range<String.Index>]()
        var overlaps: Bool = false
        
        for i in 0..<selectedUserRanges.count {
            let userRange = selectedUserRanges[i]
            
            if convertedRange.overlaps(userRange) ||
                userRange.overlaps(convertedRange) ||
                userRange.contains(convertedRange.lowerBound) ||
                userRange.contains(convertedRange.upperBound) {
                overlaps = true
            } else {
                users.append(selectedUsers[i])
                ranges.append(selectedUserRanges[i])
            }
        }
        
        if overlaps {
            selectedUsers = users
            selectedUserRanges = ranges
            updateView()
            friendsTableView.resetFilter()
            searchUsersTableView.resetDataSource(removeSelectedUsers: false)
        }
        
        return overlaps
    }
    
    private func createNewChatroom() {
        guard selectedUsers.count > 0 else { return }
        
        HUD.show(.progress)
        
        let userIds = selectedUsers.compactMap({ $0.identifier })
        
        firebaseChat.createPrivateRoom(withUserIds: userIds, game: game, completion: { [weak self]  (chatroom) in
            guard let strongself = self else { return }
            
            guard let chatroom = chatroom else {
                performOnMainThread {
                    HUD.flash(.error)
                }
                return
            }
            
            performOnMainThread {
                HUD.hide()
                strongself.view.layoutIfNeeded()
                strongself.onChatroomCreation?(strongself, chatroom)
            }
        })
    }
    
    private func addUsersToExistingChatroom() {
        guard let chatroom = chatroom,
            let addedUser = selectedUsers.last,
            let signedInUser = DataCoordinator.shared.signedInUser else { return }

        HUD.show(.progress)

        var userIds = selectedUsers.compactMap({ $0.identifier })
        userIds.append(signedInUser.identifier)
        
        firebaseChat.setUsers(userIds, forChatroom: chatroom) { [weak self] (error) in
            guard let strongself = self else { return }

            guard error == nil else {
                GGLog.error(error?.localizedDescription ?? "unknown error")
                performOnMainThread {
                    HUD.flash(.error)
                }
                return
            }

            self?.firebaseChat.sendMessage(ofType: .addedToChatroom, text: "\(signedInUser.ign) added \(addedUser.ign).", toChatroom: chatroom)

            chatroom.fetchUsers(breakCache: true)

            performOnMainThread {
                HUD.hide()
                strongself.onChatroomEdited?(strongself, chatroom)
            }
        }
    }
    
    // MARK: Interface Actions
    
    @IBAction func friendsTabButtonPressed(_ sender: Any) {
        setSearchState(newState: .friends)
    }
    
    @IBAction func allTabButtonPressed(_ sender: Any) {
        setSearchState(newState: .all)
    }
    
    @IBAction func inputTextFieldTextDidChange(_ sender: UITextField) {
        guard let text = sender.text, !text.isEmpty,
            let lastUsername = text.components(separatedBy: ", ").last, !lastUsername.isEmpty else {
                friendsTableView.resetFilter()
                searchUsersTableView.resetDataSource(removeSelectedUsers: false)
                updateView()
                return
        }
        
//        messagesTableView.isHidden = true
        friendsTableView.filter(byUsername: lastUsername)
        searchUsersTableView.searchForUsers(withIGN: lastUsername)
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        dismissSelf()
    }
    
    @IBAction func addUserButtonTapped(_ sender: UIButton) {
        guard selectedUsers.count > 0 else { return }
        
        if let chatroom = chatroom, chatroom.isGroupChat {
            addUsersToExistingChatroom()
        } else {
            createNewChatroom()
        }
    }
}

extension NewMessageViewController: TextInputViewDelegate {
    
    func textInputView(textInputView: TextInputView, heightDidChange height: CGFloat) {
        // NOP
    }
    
    func textInputView(textInputView: TextInputView, textDidChange text: String) {
        // NOP
    }
    
    func textInputView(textInputView: TextInputView, sendButtonTapped sendButton: UIButton, gif: Gif?) {
        guard selectedUsers.count > 0 else { return }
        createNewChatroom()
    }
    
    func textInputView(textInputView: TextInputView, giphyButtonTapped giphyButton: UIButton) {
        
    }
}

extension NewMessageViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateView()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateView()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        
        if textField == inputTextField {
            if text.last == " " && string.first == " " {
                return false
            }
            
            return !filterByOverlappingRanges(inText: text, withRange: range)
        }
        
        return true
    }
}

extension NewMessageViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var user: User?
        
        if tableView == friendsTableView {
            
            guard indexPath.row < friendsTableView.filteredDatasource.count else { return }
            
            user = friendsTableView.filteredDatasource[indexPath.row]
            
            tableView.reloadData()
            friendsTableView.resetFilter()
            
        } else if tableView == searchUsersTableView {
            
            user = searchUsersTableView.users[indexPath.row]
        }
        
        guard let selectedUser = user else { return }
        
        if selectedUsers.contains(where: { $0.identifier == selectedUser.identifier }) {
            // Make sure this user isn't already selected, else de-select them
            if let index = selectedUsers.firstIndex(where: { $0.identifier == selectedUser.identifier }) {
                self.selectedUsers.remove(at: index)
            }
        } else {
            selectedUsers.append(selectedUser)
            searchUsersTableView.resetDataSource(removeSelectedUsers: false)
        }
        
        updateView()
    }
}

extension NewMessageViewController: FriendsTableViewDelegate {
    
    func tableView(_ tableView: FriendsTableView, willRenderCell cell: UserTableViewCell, AtIndexPath indexPath: IndexPath) {
        guard let user = cell.user else { return }
        
        cell.showsCheckMarkButton = true
        cell.checkMarkButton.isSelected = selectedUsers.filter({ $0.identifier == user.identifier }).first != nil
    }
}
