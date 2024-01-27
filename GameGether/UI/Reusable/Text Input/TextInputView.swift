//
//  TextInputView.swift
//  GameGether
//
//  Created by James Ajhar on 8/9/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import GrowingTextView
import GiphyCoreSDK
import FLAnimatedImage

protocol TextInputViewDelegate: class {
    func textInputView(textInputView: TextInputView, textDidChange text: String)
    func textInputView(textInputView: TextInputView, heightDidChange height: CGFloat)
    func textInputView(textInputView: TextInputView, sendButtonTapped sendButton: UIButton, gif: Gif?)
    func textInputView(textInputView: TextInputView, giphyButtonTapped giphyButton: UIButton)
    func textInputViewShouldBecomeFirstResponder(_ textInputView: TextInputView) -> Bool
}

extension TextInputViewDelegate {
    // Default implementation
    func textInputViewShouldBecomeFirstResponder(_ textInputView: TextInputView) -> Bool { return true }
}

class TextInputView: UIView {
    
    private enum TextInputViewMode {
        case text
        case media
    }

    // MARK: Outlets
    @IBOutlet weak var textView: GrowingTextView! {
        didSet {
            textView.backgroundColor = UIColor(hexString: "#F8F8F8")
            textView.placeholder = "msg"
            textView.placeholderColor = UIColor(hexString: "#BDBDBD")
            textView.delegate = self
            textView.minHeight = 33
            textView.maxHeight = 100
            textView.maxLength = 300
            textView.clipsToBounds = false
            textView.isScrollEnabled = true
            textView.showsVerticalScrollIndicator = true
            textView.font = AppConstants.Fonts.robotoLight(14).font
        }
    }
    
    @IBOutlet var textViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textInputContainerView: UIView!
    @IBOutlet weak var mediaImageView: FLAnimatedImageView!
    @IBOutlet weak var mediaImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mediaImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet var mediaImageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var deleteMediaButton: UIButton!
    @IBOutlet weak var giphyButton: UIButton!
    @IBOutlet weak var giphyButtonWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var collapsedStateContainerView: UIView!
    
    @IBOutlet weak var collapsedStateTitleLabel: UILabel!  {
        didSet {
            collapsedStateTitleLabel.font = AppConstants.Fonts.robotoRegular(14).font
            collapsedStateTitleLabel.textColor = UIColor(hexString: "#BDBDBD")
        }
    }
    @IBOutlet weak var collapsedStateImageView: UIImageView!

    // MARK: Properties
    weak var delegate: TextInputViewDelegate?
    
    var showsGiphyButton: Bool = true {
        didSet {
            giphyButton.isHidden = !showsGiphyButton
            giphyButtonWidthConstraint.constant = showsGiphyButton ? 40 : 4
            layoutIfNeeded()
        }
    }
    
    var showsSendButton: Bool = true {
        didSet {
            updateSendButton()
        }
    }
    
    var minHeight: CGFloat {
        get {
            return textView.minHeight
        }
        set {
            textView.minHeight = newValue
        }
    }
    
    var maxHeight: CGFloat {
        get {
            return textView.maxHeight
        }
        set {
            textView.maxHeight = newValue
        }
    }
    
    var gif: Gif? {
        didSet {
            sendButton.isHidden = showsSendButton && gif == nil && text.isEmpty
        }
    }
    
    var text: String {
        return textView.text
    }
    
    var maxTextLength: UInt = 255
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textInputContainerView.layer.cornerRadius = 8.0
        textInputContainerView.layer.borderColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1).cgColor
        textInputContainerView.layer.borderWidth = 1
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(mediaViewTapped))
        mediaImageView.addGestureRecognizer(tap)
        
        let viewTap = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        viewTap.cancelsTouchesInView = false
        textInputContainerView.addGestureRecognizer(viewTap)
        collapsedStateContainerView.addGestureRecognizer(viewTap)
        
        // Default mode is text
        setMode(.text)
        
        layoutIfNeeded()
    }
    
    @objc func mediaViewTapped() {
        // Tapping the media view should behave the same way as tapping a textview (in terms of becoming first responder)
        textView.becomeFirstResponder()
    }
    
    @objc func viewTapped() {
        // Tapping the view should behave the same way as tapping the textview (in terms of becoming first responder)
        textView.becomeFirstResponder()
    }
    
    func setMediaURL(_ url: URL, withSize size: CGSize) {
        gif = Gif(mediaURL: url, size: size)
        mediaImageView.sd_setImage(with: url, completed: nil)
        setMode(.media)
        mediaImageWidthConstraint.constant = size.width > 200 ? 200 : size.width
        mediaImageHeightConstraint.constant = size.height
        layoutIfNeeded()
        delegate?.textInputView(textInputView: self, heightDidChange: bounds.height)
    }
    
    public func toggleCollapsedState(collapsed: Bool) {
        collapsedStateContainerView.isHidden = !collapsed
        textInputContainerView.isHidden = collapsed
    }
    
    private func updateSendButton() {
        sendButton.isHidden = !showsSendButton || (textView.text.isEmpty && gif == nil)
    }
    
    private func setMode(_ mode: TextInputViewMode) {
        switch mode {
        case .text:
            // Allow the text view to grow and define the height of this view
            textViewTopConstraint.isActive = true
            mediaImageViewBottomConstraint.isActive = false
            textView.isHidden = false
            mediaImageView.isHidden = true
            deleteMediaButton.isHidden = true
        case .media:
            // Allow the media image view to grow and define the height of this view. Requires taking this control away from the text view.
            textViewTopConstraint.isActive = false
            mediaImageViewBottomConstraint.isActive = true
            textView.isHidden = true
            mediaImageView.isHidden = false
            deleteMediaButton.isHidden = false
        }
    }
    
    // MARK: Interface Actions
    
    @IBAction func sendMessageButtonTapped(_ sender: UIButton) {
        guard showsSendButton else { return }
        
        delegate?.textInputView(textInputView: self, sendButtonTapped: sender, gif: gif)
        textView.text = ""
        gif = nil
        mediaImageView.animatedImage = nil
        sendButton.isHidden = true
        setMode(.text)
        layoutIfNeeded()
        delegate?.textInputView(textInputView: self, heightDidChange: bounds.height)
    }
    
    @IBAction func giphyButtonPressed(_ sender: UIButton) {
        delegate?.textInputView(textInputView: self, giphyButtonTapped: sender)
    }
    
    @IBAction func deleteMediaButtonPressed(_ sender: UIButton) {
        gif = nil
        mediaImageView.animatedImage = nil
        sendButton.isHidden = true
        setMode(.text)
        layoutIfNeeded()
        delegate?.textInputView(textInputView: self, heightDidChange: bounds.height)
    }
}

extension TextInputView: GrowingTextViewDelegate {
    
    func textViewDidChangeHeight(_ textView: GrowingTextView, height: CGFloat) {
        layoutIfNeeded()
        delegate?.textInputView(textInputView: self, heightDidChange: bounds.height)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        updateSendButton()
        delegate?.textInputView(textInputView: self, textDidChange: textView.text)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        guard text.rangeOfCharacter(from: .newlines) == nil else {
            // send button pressed
            sendMessageButtonTapped(sendButton)
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
        
        guard isBackspace || updatedText.count <= maxTextLength else {
            return false
        }
        
        return true
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if let delegate = delegate {
            return delegate.textInputViewShouldBecomeFirstResponder(self)
        }
        return true
    }
}
