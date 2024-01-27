//
//  ProfileInfoHeaderView.swift
//  GameGether
//
//  Created by James Ajhar on 5/28/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class ProfileInfoHeaderView: UIView {
  
    struct Constants {
        static var maxSubtitleCharCount: Int = 25
        static var maxAboutCharCount: Int = 160
    }
    
    enum ProfileInfoHeaderViewMode {
        case viewing
        case editing
    }
    
    // MARK: - Outlets
    @IBOutlet weak var ignLabel: UILabel!
    
    @IBOutlet weak var profileImageShadowView: UIView! {
       didSet {
           profileImageShadowView.addDropShadow(color: .black, opacity: 0.33, offset: CGSize(width: 1, height: 5), radius: 5)
       }
    }
    @IBOutlet weak var profileImageView: AvatarInitialsImageView!
    
    @IBOutlet weak var subtitleLabel: UILabel!
    
    @IBOutlet weak var aboutTextView: UITextView! {
        didSet {
            aboutTextView.cornerRadius = 5
            aboutTextView.borderColor = UIColor(hexString: "#707070")
            aboutTextView.placeholderText = "say something about yourself"
            aboutTextView.font = AppConstants.Fonts.robotoLight(12).font
        }
    }
    
    @IBOutlet weak var sectionBar: SectionBarView!
    @IBOutlet weak var userStatusImageView: UserStatusImageView!
    @IBOutlet weak var playWithButton: UIButton!
    @IBOutlet weak var socialIconStack: SocialIconStackView!
    @IBOutlet weak var socialIconStackTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var addFriendButton: UIButton!
    @IBOutlet weak var hyperLinkButton: UIButton!
    
    // Editing Mode
    @IBOutlet weak var aboutTitleLabel: UILabel!
    @IBOutlet weak var subtitleTextField: UITextField!
    @IBOutlet weak var subtitleCharCountLabel: UILabel!
    @IBOutlet weak var aboutCharCountLabel: UILabel!
    @IBOutlet weak var editProfilePicButton: UIButton!
    
    // MARK: - Properties
    
    var currentMode: ProfileInfoHeaderViewMode = .viewing {
        didSet {
            setMode(currentMode)
        }
    }
    
    var onPlayWithPressed: ((UIButton) -> Void)?
    var onEditPressed: ((UIButton) -> Void)?
    var onSettingsPressed: ((UIButton) -> Void)?
    var onEditProfilePicPressed: ((UIButton) -> Void)?
    var onAddFriendPressed: ((UIButton) -> Void)?

    var onSocialLinkTapped: ((SocialLink) -> Void)? {
        didSet {
            socialIconStack.onSocialLinkTapped = onSocialLinkTapped
        }
    }
    
    var user: User? {
        didSet {
            setupWithUser()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        styleUI()
        
        sectionBar.delegate = self
        sectionBar.numberOfTabs = 1
        
        subtitleTextField.delegate = self
        aboutTextView.delegate = self
        
        currentMode = .viewing
    }
    
    private func styleUI() {
        // IGN
        ignLabel.font = AppConstants.Fonts.robotoMedium(15).font
        
        // Tagline
        subtitleLabel.font = AppConstants.Fonts.robotoLight(12).font
        subtitleLabel.textColor = UIColor(hexString: "#828282")
        
        // Profile Image
        profileImageView.cornerRadius = profileImageView.bounds.width / 2
        profileImageShadowView.addDropShadow(color: .black, opacity: 0.33, offset: CGSize(width: 1, height: 5), radius: 5)
        profileImageShadowView.cornerRadius = profileImageView.cornerRadius
        
        // Ask to play Button
        playWithButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(14).font
        
        // Edit Button
        editButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(14).font
        editButton.setTitleColor(UIColor(hexString: "#57A2E1"), for: .normal)
        editButton.borderColor = UIColor(hexString: "#57A2E1")
        editButton.borderWidth = 1
        
        // Editing Mode
        subtitleTextField.font = AppConstants.Fonts.robotoLight(12).font
        subtitleTextField.borderColor = UIColor(hexString: "#707070")
        subtitleTextField.borderWidth = 1
        subtitleTextField.cornerRadius = 5
        subtitleTextField.setLeftPaddingPoints(3)
        
        subtitleCharCountLabel.font = AppConstants.Fonts.robotoLight(12).font
        subtitleCharCountLabel.textColor = UIColor(hexString: "#ACACAC")
        
        aboutCharCountLabel.font = AppConstants.Fonts.robotoLight(12).font
        aboutCharCountLabel.textColor = UIColor(hexString: "#ACACAC")

        aboutTitleLabel.font = AppConstants.Fonts.robotoMedium(12).font

        editProfilePicButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25)
        editProfilePicButton.cornerRadius = editProfilePicButton.bounds.width / 2
    }
    
    private func setupWithUser() {
        guard let user = user else { return }
        
        ignLabel.text = user.ign
        subtitleLabel.text = user.tagline
        subtitleTextField.text = user.tagline
        
        if let tagline = user.tagline, !tagline.isEmpty {
            subtitleLabel.text = tagline
        } else {
            subtitleLabel.text = "new to gamegether, gg!"
        }
        
        if let about = user.about, !about.isEmpty {
            aboutTextView.text = about
        } else {
            aboutTextView.text = "hey, add me on gg!"
        }
        
        updateAddFriendButton()
        
        profileImageView.configure(withUser: user, andFont: AppConstants.Fonts.robotoRegular(30).font)
        
        if user.isSignedInUser {
            // signed in user is always online, no need to observe
            userStatusImageView.status = .online
        } else {
            user.observeStatus { [weak self] (status, _) in
                self?.userStatusImageView.status = status
            }
        }
        
        if user.socialLinks.isEmpty, user.isSignedInUser, currentMode == .viewing {
            // Show empty state hyperlink icon
            hyperLinkButton.isHidden = false
            socialIconStack.socialLinks.removeAll()
        } else {
            // Show social links for this user
            hyperLinkButton.isHidden = true
            socialIconStack.socialLinks = user.socialLinks
        }
        
        playWithButton.isHidden = user.isSignedInUser || user.relationship?.status == .blocked
        editButton.isHidden = !user.isSignedInUser || currentMode == .editing
        settingsButton.isHidden = !user.isSignedInUser || currentMode == .editing
        
        subtitleCharCountLabel.text = "\(user.tagline?.count ?? 0)/\(Constants.maxSubtitleCharCount) characters"
        aboutCharCountLabel.text = "\(user.about?.count ?? 0)/\(Constants.maxAboutCharCount) characters"
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        if let textView = view as? UITextView, textView.isEditable {
            return view
        }
        
        return view == socialIconStack || view is UIButton || view is UITextField ? view : nil
    }
    
    private func setMode(_ mode: ProfileInfoHeaderViewMode) {
        // TODO: Clean this up
        switch mode {
        case .viewing:
            subtitleTextField.isHidden = true
            subtitleCharCountLabel.isHidden = true
            aboutCharCountLabel.isHidden = true
            subtitleLabel.isHidden = false
            aboutTextView.isEditable = false
            aboutTextView.spellCheckingType = .no
            aboutTextView.layer.borderWidth = 0
            editButton.isHidden = false
            aboutTitleLabel.isHidden = true
            editProfilePicButton.isHidden = true
            socialIconStack.showAllLinkTypes = false
            hyperLinkButton.isHidden = false
            
            socialIconStackTopConstraint.constant = 21

        case .editing:
            subtitleTextField.isHidden = false
            subtitleCharCountLabel.isHidden = false
            aboutCharCountLabel.isHidden = false
            subtitleLabel.isHidden = true
            aboutTextView.isEditable = true
            aboutTextView.spellCheckingType = .yes
            editProfilePicButton.isHidden = false
            socialIconStack.showAllLinkTypes = true
            hyperLinkButton.isHidden = true

            socialIconStackTopConstraint.constant = 16
            
            aboutTitleLabel.isHidden = false
            aboutTextView.layer.borderWidth = 1
            editButton.isHidden = true
        }
        
        if let user = user, user.socialLinks.isEmpty, user.isSignedInUser, currentMode == .viewing {
            hyperLinkButton.isHidden = false
        } else {
            hyperLinkButton.isHidden = true
        }
        
        // This resets the red squiggle spell checking
        let aboutText = aboutTextView.text
        aboutTextView.text = ""
        aboutTextView.text = aboutText
    }
    
    private func updateAddFriendButton() {
        addFriendButton.isHidden = user?.isSignedInUser == true
        
        guard let relationship = user?.relationship else {
            addFriendButton.setImage(#imageLiteral(resourceName: "Add Friend"), for: .normal)
            return
        }
                
        switch relationship.status {
        case .none:
            addFriendButton.setImage(#imageLiteral(resourceName: "Add Friend"), for: .normal)
            
        case .pending:
            
            if relationship.wasSentToMe {
                addFriendButton.setImage(#imageLiteral(resourceName: "Add Friend"), for: .normal)
            } else {
                addFriendButton.setImage(#imageLiteral(resourceName: "FriendRequestPending"), for: .normal)
            }
            
        case .accepted:
            addFriendButton.setImage(#imageLiteral(resourceName: "Friends"), for: .normal)
            
        case .blocked:
            addFriendButton.isHidden = true
        }
    }
    
    // MARK: - Interface Actions
    
    @IBAction func playWithButtonPressed(_ sender: UIButton) {
        onPlayWithPressed?(sender)
    }
    
    @IBAction func editButtonPressed(_ sender: UIButton) {
        currentMode = .editing
        onEditPressed?(sender)
    }
    
    @IBAction func settingsButtonPressed(_ sender: UIButton) {
        onSettingsPressed?(sender)
    }
    
    @IBAction func editProfilePicButtonPressed(_ sender: UIButton) {
        onEditProfilePicPressed?(sender)
    }
    
    @IBAction func addFriendButtonPressed(_ sender: UIButton) {
        onAddFriendPressed?(sender)
    }
    
    @IBAction func addSocialLinkButtonPressed(_ sender: UIButton) {
        // Use the same action as edit button
        currentMode = .editing
        onEditPressed?(sender)
    }
}

extension ProfileInfoHeaderView: SectionBarViewDelegate {
    
    func sectionBarView(view: SectionBarView, titleForTabAt index: Int) -> String {
        return "Games"
    }
    
    func sectionBarView(view: SectionBarView, didSelectTabAt index: Int) {
        // NOP
    }
}

extension ProfileInfoHeaderView: UITextFieldDelegate, UITextViewDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == subtitleTextField {
            // limit to 25 characters max
            let currentText = textField.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            
            var isBackspace = false
            
            if let char = string.cString(using: String.Encoding.utf8) {
                let backspaceCompare = strcmp(char, "\\b")
                if (backspaceCompare == -92) {
                    isBackspace = true
                }
            }
            
            guard isBackspace || updatedText.count <= Constants.maxSubtitleCharCount else {
                return false
            }
            
            subtitleCharCountLabel.text = "\(updatedText.count)/\(Constants.maxSubtitleCharCount) characters"
        }
        
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        if textView == aboutTextView {
            guard text.rangeOfCharacter(from: .newlines) == nil else {
                // prevent newlines
                return false
            }
            
            var isBackspace = false
            
            if let char = text.cString(using: String.Encoding.utf8) {
                let backspaceCompare = strcmp(char, "\\b")
                if (backspaceCompare == -92) {
                    isBackspace = true
                }
            }

            guard let stringRange = Range(range, in: textView.text) else { return false }

            let updatedText = textView.text.replacingCharacters(in: stringRange, with: text)

            guard isBackspace || updatedText.count <= Constants.maxAboutCharCount else {
                return false
            }
            
            aboutCharCountLabel.text = "\(updatedText.count)/\(Constants.maxAboutCharCount) characters"
        }

        return true
    }

}
