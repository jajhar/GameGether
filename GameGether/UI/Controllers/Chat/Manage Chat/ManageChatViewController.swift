//
//  ManageChatViewController.swift
//  GameGether
//
//  Created by James Ajhar on 8/19/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD

class ManageChatViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var multiAvatarView: MultiAvatarView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var leftNavButton: UIButton!
    @IBOutlet weak var rightNavButton: UIButton!
    @IBOutlet weak var usersTableView: ChatroomUsersTableView!
    @IBOutlet weak var notificationsTitleLabel: UILabel!
    @IBOutlet weak var chatroomImageView: UIImageView!
    @IBOutlet weak var chatroomNameField: UITextField!
    @IBOutlet weak var muteSwitch: UISwitch!
    @IBOutlet weak var leaveChatButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var editViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: Properties
    var chatroom: FRChatroom?
    let imagePicker = UIImagePickerController()
    private var pickedImage: UIImage?
    private(set) var firebaseChat = FirebaseChat()
    private(set) var isEditingChat: Bool = false
    
    var showEditButton: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        styleUI()
        chatroomImageView.layer.cornerRadius = chatroomImageView.bounds.width / 2
        hideKeyboardWhenBackgroundTapped()
        
        rightNavButton.isHidden = !showEditButton
        
        if !showEditButton {
            editViewHeightConstraint.constant = 0
        }
        
        firebaseChat.signIn()
        
        if let chatroom = chatroom {
            firebaseChat.observeChatroom(chatroom) { [weak self] (chatroom) in
                performOnMainThread {
                    self?.chatroom = chatroom
                    self?.setupWithChatroom()
                }
            }
        }

        usersTableView.onMessageButtonTapped = { [weak self] (user) in
            self?.createChatroom(withUser: user)
        }
    }
    
    private func styleUI() {
        titleLabel.font = AppConstants.Fonts.robotoBold(16).font
        rightNavButton.titleLabel?.font = AppConstants.Fonts.robotoBold(16).font
        leftNavButton.titleLabel?.font = AppConstants.Fonts.robotoBold(16).font
        chatroomNameField.font = AppConstants.Fonts.robotoRegular(14).font
        usernameLabel.font = AppConstants.Fonts.robotoRegular(14).font
        notificationsTitleLabel.font = AppConstants.Fonts.robotoMedium(16).font
        leaveChatButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(16).font
    }

    private func setupWithChatroom() {
        guard let chatroom = chatroom else { return }
        
        muteSwitch.isOn = !DataCoordinator.shared.isChatroomMuted(chatroomId: chatroom.identifier)

        // Cannot leave 1:1 Chatrooms
        leaveChatButton.isHidden = !chatroom.isGroupChat && chatroom.session == nil
        
        usersTableView.chatroom = chatroom
        
        chatroom.fetchUsers { [weak self] (users) in
            
            guard let strongself = self, let users = users else { return }
            
            performOnMainThread {
                
                if let imageURL = chatroom.imageURL {
                    self?.multiAvatarView.isHidden = true
                    self?.chatroomImageView.sd_setImage(with: imageURL, placeholderImage: #imageLiteral(resourceName: "Pastel Green #66CC33"), options: [], completed: nil)
                } else {
                    self?.multiAvatarView.isHidden = false
                    self?.multiAvatarView.users = users
                }
                
                if let name = chatroom.name, !name.isEmpty {
                    strongself.usernameLabel.text = name
                    strongself.chatroomNameField.text = name
                    
                } else {
                    if chatroom.isGroupChat {
                        strongself.usernameLabel.attributedText = users.fullIGNText
                        
                    } else if let user = users.first {
                        strongself.usernameLabel.attributedText = user.fullIGNText
                    }
                }
            }
        }
    }
    
    private func presentImagePicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            presentGenericAlert(title: "Access Denied", message: "You must allow the app to access your photo library in order to upload a photo. Please go to Settings->Privacy->Photos and allow GameGether to access your photo library.")
            return
        }
        
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func updateChatroomNameIfneeded() {
        guard let chatroom = chatroom, let newName = chatroomNameField.text, newName != chatroom.name else { return }
        firebaseChat.updateChatroomName(forChatroom: chatroom, newName: newName)
        chatroom.name = newName
        setupWithChatroom()
    }
    
    private func uploadImageIfNeeded() {
        guard let pickedImage = pickedImage,
            let chatroom = chatroom else { return }
        
        guard let imageData = pickedImage.jpegRepresentation() else {
            GGLog.error("Failed to convert image to jpeg representation.")
            return
        }
        
        HUD.show(.progress)
        
        DataCoordinator.shared.s3Uploader.upload(data: imageData,
                                                 contentType: .image,
                                                 progress:
            { (task, progress) in
                GGLog.debug("Upload Progress: \(progress)")
                
        }) { [weak self] (url, error) in
            performOnMainThread {
                guard let strongself = self, error == nil, let url = url else {
                    GGLog.error("Upload Failed: \(String(describing: error?.localizedDescription))")
                    HUD.flash(.error, delay: 1.0)
                    return
                }
                
                strongself.firebaseChat.updateChatroomImage(forChatroom: chatroom, imageURL: url)
                strongself.chatroom?.imageURL = url
                strongself.setupWithChatroom()

                HUD.hide()
            }
        }
    }
    
    private func setEditingMode(isEditing: Bool) {
        isEditingChat = isEditing
        
        if isEditingChat {
            rightNavButton.setTitle("done", for: .normal)
            leftNavButton.setTitle("cancel", for: .normal)
        } else {
            usernameLabel.isHidden = false
            chatroomNameField.isHidden = true
            rightNavButton.setTitle("edit", for: .normal)
            leftNavButton.setTitle("back", for: .normal)
        }
    }

    private func createChatroom(withUser user: User) {
        HUD.show(.progress)

        firebaseChat.createPrivateRoom(withUserIds: [user.identifier], completion: { [weak self]  (chatroom) in
            guard let weakSelf = self else { return }

            guard let chatroom = chatroom else {
                performOnMainThread {
                    HUD.flash(.error)
                }
                return
            }

            performOnMainThread {
                HUD.hide()

                let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
                viewController.chatroom = chatroom
                weakSelf.navigationController?.pushViewController(viewController, animated: true)
            }
        })
    }
    
    // MARK: Interface Actions
    
    @IBAction func leftNavButtonPressed(_ sender: UIButton) {
        if isEditingChat {
            // Cancel button pressed
            setEditingMode(isEditing: false)
            pickedImage = nil
            chatroomNameField.isHidden = true
            chatroomNameField.text = ""
            usernameLabel.isHidden = false
            setupWithChatroom()
        } else {
            // Back button pressed
            dismissSelf()
        }
    }
    
    @IBAction func muteButtonToggled(_ sender: Any) {
        guard let chatroom = chatroom else { return }
        
        HUD.show(.progress)

        if DataCoordinator.shared.isChatroomMuted(chatroomId: chatroom.identifier) {
            // Unmute this chatroom
            AnalyticsManager.track(event: .manageChatNotificationsOn, withParameters: ["chatroom": chatroom.identifier])
            
            DataCoordinator.shared.unmute(chatroomWithId: chatroom.identifier) { [weak self] (_, error) in
                guard let strongSelf = self else { return }
                
                performOnMainThread {
                    HUD.hide()
                    guard error == nil else {
                        GGLog.error("Error: \(String(describing: error))")
                        strongSelf.muteSwitch.isOn = false
                        strongSelf.presentGenericErrorAlert()
                        return
                    }
                    
                    strongSelf.muteSwitch.isOn = true
                }
            }
        } else {
            // Mute this chatroom
            AnalyticsManager.track(event: .manageChatNotificationsOff, withParameters: ["chatroom": chatroom.identifier])

            DataCoordinator.shared.mute(chatroomWithId: chatroom.identifier) { [weak self] (_, error) in
                guard let strongSelf = self else { return }
                
                performOnMainThread {
                    HUD.hide()
                    guard error == nil else {
                        GGLog.error("Error: \(String(describing: error))")
                        strongSelf.muteSwitch.isOn = true
                        strongSelf.presentGenericErrorAlert()
                        return
                    }
                    
                    strongSelf.muteSwitch.isOn = false
                }
            }
        }
    }
    
    @IBAction func editButtonPressed(_ sender: UIButton) {
                
        setEditingMode(isEditing: !isEditingChat)
        
        guard isEditingChat else {
            uploadImageIfNeeded()
            updateChatroomNameIfneeded()
            return
        }
        
        AnalyticsManager.track(event: .manageChatEditButtonPressed, withParameters: ["chatroom": chatroom?.identifier ?? ""])
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "change name", style: .default, handler: { (action) in
            AnalyticsManager.track(event: .manageChatEditNameButtonPressed, withParameters: ["chatroom": self.chatroom?.identifier ?? ""])
            self.chatroomNameField.isHidden = false
            self.usernameLabel.isHidden = true
            self.chatroomNameField.becomeFirstResponder()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "change photo", style: .default, handler: { (action) in
            AnalyticsManager.track(event: .manageChatEditPhotoButtonPressed, withParameters: ["chatroom": self.chatroom?.identifier ?? ""])
            self.presentImagePicker()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action) in
            self.setEditingMode(isEditing: false)
            actionSheet.dismiss(animated: true, completion: nil)
        }))
        
        actionSheet.show()
    }
    
    @IBAction func leaveChatroomPressed(_ sender: UIButton) {
        guard let chatroom = chatroom else { return }
        
        var title: String = ""
        var message: String = ""
        
        if chatroom.session != nil {
            title = "leave session?"
            message = "Are you sure you want to leave this LFG session?"
            
        } else {
            title = chatroom.isGroupChat ? "leave group?" : "leave chat?"
            message = chatroom.isGroupChat ? "Leaving this chat group will require an invitation to rejoin." : "Leaving this chat will require an invitation to rejoin."
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "leave", style: .destructive, handler: { (action) in
            
            AnalyticsManager.track(event: .manageChatLeaveButtonPressed, withParameters: ["chatroom": chatroom.identifier])
            HUD.show(.progress)
            
            self.firebaseChat.leaveChatroom(chatroom, completion: { [weak self] (error) in
                guard let weakSelf = self else { return }
                performOnMainThread {
                    
                    HUD.hide()
                    
                    guard error == nil else {
                        weakSelf.presentGenericErrorAlert()
                        return
                    }
                    
                    // Leave any active calls
                    FloatingAudioView.activeView?.hangup()
                    weakSelf.navigationController?.popToRootViewController(animated: true)
                }
            })
            
            if let session = chatroom.session {
                // Leave any session this user has joined from this chatroom via association.
                
                AnalyticsManager.track(event: .sessionLeft, withParameters: ["session": session.identifier])
                
                DataCoordinator.shared.leaveGameSession(session) { (error) in
                    if let error = error {
                        GGLog.error(error.localizedDescription)
                    }
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: "stay", style: .cancel, handler: { (action) in
            // NOP
        }))
        
        alert.show()
    }
}

// MARK: UIImagePickerControllerDelegate

extension ManageChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        
        if let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage {
            pickedImage = UIImage.imageWithImage(sourceImage: image, scaledToWidth: 300)
        }
        
        chatroomImageView.image = pickedImage
        multiAvatarView.isHidden = true
        
        picker.dismiss(animated: true, completion: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
