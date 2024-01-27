//
//  CreateLFGViewController.swift
//  GameGether
//
//  Created by James Ajhar on 12/5/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import BABFrameObservingInputAccessoryView
import PKHUD

class CreateLFGViewController: UIViewController {

    struct Constants {
        static let maxLFGTextLength: UInt = 80
    }
    
    // MARK: - Outlets
    @IBOutlet weak var cancelButton: UIButton! {
        didSet {
            cancelButton.titleLabel?.font = AppConstants.Fonts.robotoBold(16).font
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.font = AppConstants.Fonts.robotoBold(20).font
        }
    }
    
    @IBOutlet weak var postButton: UIButton! {
        didSet {
            postButton.titleLabel?.font = AppConstants.Fonts.robotoBold(16).font
            postButton.setTitleColor(UIColor(hexString: "#CCCCCC"), for: .disabled)
            postButton.setTitleColor(.white, for: .normal)
            postButton.isEnabled = false
        }
    }
    
    @IBOutlet weak var scrollView: KeyboardScrollView!
    @IBOutlet weak var previewContainerView: UIView!
    @IBOutlet weak var previewGameImageView: UIImageView!
    @IBOutlet weak var userImageView: UIImageView!

    @IBOutlet weak var previewTextView: UITextView! {
        didSet {
            previewTextView.font = AppConstants.Fonts.robotoMedium(14).font
            previewTextView.textContainerInset = UIEdgeInsets(top: 11, left: 11, bottom: 11, right: 11)
        }
    }
    
    @IBOutlet weak var previewTagsCollectionView: TagsDisplayCollectionView! {
        didSet {
            previewTagsCollectionView.cellHeight = 15
            previewTagsCollectionView.cellPadding = 2
            previewTagsCollectionView.cellFont = AppConstants.Fonts.robotoBold(11).font
            
            previewTagsCollectionView.onReload = { [weak self] in
                guard let weakSelf = self else { return }
                // Resize to fit content
                weakSelf.tagsCollectionHeightConstraint.constant = weakSelf.previewTagsCollectionView.collectionViewLayout.collectionViewContentSize.height
                weakSelf.view.layoutIfNeeded()
            }
        }
    }
    @IBOutlet weak var tagsCollectionHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var textInputContainerView: UIView!
    @IBOutlet weak var textInputContainerBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var charCountLabel: UILabel! {
        didSet {
            charCountLabel.textColor = UIColor(hexString: "#ACACAC")
            charCountLabel.font = AppConstants.Fonts.robotoLight(12).font
            charCountLabel.text = "0/\(Constants.maxLFGTextLength) characters"
        }
    }
    
    @IBOutlet weak var minCharCountLabel: UILabel! {
        didSet {
            minCharCountLabel.textColor = UIColor(hexString: "#ACACAC")
            minCharCountLabel.font = AppConstants.Fonts.robotoLight(12).font
            minCharCountLabel.text = "minimum of 5 characters required"
        }
    }
    
    // MARK: - Properties
        
    private let textInputView: TextInputView = {
        let nib = UINib(nibName: TextInputView.nibName, bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil).first as! TextInputView
        view.translatesAutoresizingMaskIntoConstraints = false
        view.maxTextLength = Constants.maxLFGTextLength
        view.textView.returnKeyType = .default
        view.textView.keyboardType = .twitter
        view.textView.placeholder = "type in your request"
        view.showsGiphyButton = false
        view.showsSendButton = false
        
        return view
    }()
    
    var game: Game?
    var tags = [Tag]()
    var onPostCreated: ((GameSession) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        disableDarkMode()
        configureTextInputView()
        configurePreviewView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textInputView.textView.becomeFirstResponder()
    }
    
    private func configurePreviewView() {
        previewContainerView.backgroundColor = UIColor(hexString: game?.headerColor ?? "#000000")
        userImageView.sd_setImage(with: DataCoordinator.shared.signedInUser?.profileImageURL ?? game?.tagThemeImageURL, completed: nil)
        previewGameImageView.sd_setImage(with: game?.iconImageURL, completed: nil)
        previewTagsCollectionView.tags = tags
    }
    
    private func configureTextInputView() {
        
        // Add text input field
        textInputContainerView.addSubview(textInputView)
        textInputView.delegate = self
        textInputView.constrainToSuperview()
        textInputView.textView.keyboardDismissMode = .none
        
        let keyboardObserverInputView = BABFrameObservingInputAccessoryView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 44))
        textInputView.textView.inputAccessoryView = keyboardObserverInputView
        
        keyboardObserverInputView.keyboardFrameChangedBlock = { [weak self] (_, newFrame) in
            performOnMainThread {
                guard let weakSelf = self else { return }
                
                let offset: CGFloat = UIDevice.current.hasNotch ? 30 : 0
                let screenHeight = UIScreen.main.bounds.height
                var value: CGFloat = screenHeight - (keyboardObserverInputView.superview?.frame.minY ?? 0) - keyboardObserverInputView.frame.height - offset

                if value < 0 {
                    value = 0
                }
                
                weakSelf.textInputContainerBottomConstraint?.constant = value
                weakSelf.view.layoutIfNeeded()
            }
        }
    }
    
    private func createGameSession(withDescription description: String) {
        
        guard let game = game, !tags.isEmpty else {
            return
        }
        
        HUD.show(.progress)
        
        // Disable the UI while this request goes through
        view.isUserInteractionEnabled = false
        
        DataCoordinator.shared.createGameSession(forGame: game.identifier,
                                                   withTags: tags,
                                                   sessionDescription: description)
        { [weak self] (newSession, chatroomId, error) in
            guard let weakSelf = self else { return }
            
            performOnMainThread {
                HUD.hide()

                guard error == nil, let newSession = newSession else {
                    weakSelf.view.isUserInteractionEnabled = true
                    GGLog.error(error?.localizedDescription ?? "Unknown error")
                    weakSelf.presentGenericErrorAlert()
                    return
                }
                
                weakSelf.onPostCreated?(newSession)
            }
        }
    }
    
    // MARK: - Interface Actions
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .createLFGCancelPressed)
        dismissSelf()
    }
    
    @IBAction func postButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .createLFGPostPressed, withParameters: [
            "session_description": textInputView.text
        ])

        createGameSession(withDescription: textInputView.text)
    }
}

extension CreateLFGViewController: TextInputViewDelegate {
    
    func textInputView(textInputView: TextInputView, textDidChange text: String) {
        charCountLabel.text = "\(text.count)/\(Constants.maxLFGTextLength) characters"
        previewTextView.text = text
        postButton.isEnabled = text.count >= 5
    }
    
    func textInputView(textInputView: TextInputView, heightDidChange height: CGFloat) {
        // NOP
    }
    
    func textInputView(textInputView: TextInputView, sendButtonTapped sendButton: UIButton, gif: Gif?) {
        guard !textInputView.text.isEmpty else { return }
//        createGameSession(withDescription: textInputView.text)
    }
    
    func textInputView(textInputView: TextInputView, giphyButtonTapped giphyButton: UIButton) {
        // NOP
    }
}

