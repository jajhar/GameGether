//
//  RequestSessionTextInputViewController.swift
//  GameGether
//
//  Created by James Ajhar on 10/2/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import BABFrameObservingInputAccessoryView

class RequestSessionTextInputViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var textInputContainerView: UIView!
    @IBOutlet weak var textInputViewBottomConstraint: NSLayoutConstraint!
   
    @IBOutlet weak var partySizeButton: UIButton! {
        didSet {
            partySizeButton.titleLabel?.font = AppConstants.Fonts.robotoRegular(12).font
            partySizeButton.setTitleColor(UIColor(hexString: "#3399FF"), for: .normal)
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.font = AppConstants.Fonts.robotoRegular(14).font
            let text = NSMutableAttributedString(string: "+ type in your request (required)")
            text.addColor(color: UIColor(hexString: "#ACACAC"), toText: "+ type in your request")
            text.addColor(color: UIColor(hexString: "#FA9917"), toText: "(required)")
            titleLabel.attributedText = text
        }
    }
    
    @IBOutlet weak var exampleTitleLabel: UILabel! {
        didSet {
            exampleTitleLabel.font = AppConstants.Fonts.robotoRegular(14).font
        }
    }
    
    @IBOutlet weak var charCountLabel: UILabel! {
        didSet {
            charCountLabel.textColor = UIColor(hexString: "#ACACAC")
            charCountLabel.font = AppConstants.Fonts.robotoLight(12).font
            charCountLabel.text = "0/160 characters"
        }
    }
    
    // MARK: - Properties
    
    private let textInputView: TextInputView = {
        let nib = UINib(nibName: TextInputView.nibName, bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil).first as! TextInputView
        view.translatesAutoresizingMaskIntoConstraints = false
        view.maxTextLength = 160
        view.textView.returnKeyType = .done
        view.textView.placeholder = "type in your request"
        view.showsGiphyButton = false
        view.showsSendButton = false
        return view
    }()
    
    var initialText: String?
    var game: Game?
    var selectedTags = [Tag]()
    
    // Returns the text and the party size selected
    var onTextSubmitted: ((String, UInt) -> Void)?

    private(set) var selectedPartySize: UInt = 2    // default is 2

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTextView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textInputView.textView.becomeFirstResponder()
    }
    
    private func configureTextView() {
        
        // Add text input field
        textInputContainerView.addSubview(textInputView)
        textInputView.delegate = self
        textInputView.constrainToSuperview()

        textInputView.textView.text = initialText
        
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
                
                weakSelf.textInputViewBottomConstraint?.constant = value
                weakSelf.view.layoutIfNeeded()
            }
        }
    }
    
    private func showPartySizeSelector() {
        guard let game = game else { return }
        
        guard selectedTags.sizeTags().isEmpty else {
            showPartySizeAlert(withSizes: selectedTags.sizeTags())
            return
        }
        
        DataCoordinator.shared.getTags(forGame: game.identifier) { [weak self] (remoteTags, error) in
            guard let weakSelf = self, error == nil, let remoteTags = remoteTags else {
                GGLog.error("Error: \(String(describing: error))")
                return
            }
            
            performOnMainThread {
                weakSelf.showPartySizeAlert(withSizes: remoteTags.sizeTags())
            }
        }
    }
    
    private func showPartySizeAlert(withSizes sizeTags: [Tag]) {
        let alert = UIAlertController(title: "select a party size", message: nil, preferredStyle: .actionSheet)

        var sizeTags = sizeTags
        sizeTags.sortByPriority()
        
        for sizeTag in sizeTags {

            alert.addAction(UIAlertAction(title: sizeTag.title, style: .default, handler: { (_) in
                self.partySizeButton.setTitle("Party Size = \(sizeTag.size)", for: .normal)
                self.selectedPartySize = UInt(sizeTag.size)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Interface Actions
    
    @IBAction func backButtonPressed(_ sender: Any) {
        dismissSelf()
    }
    
    @IBAction func partySizeButtonPressed(_ sender: Any) {
        showPartySizeSelector()
    }
    
}

extension RequestSessionTextInputViewController: TextInputViewDelegate {
    
    func textInputView(textInputView: TextInputView, textDidChange text: String) {
        charCountLabel.text = "\(text.count)/160 characters"
    }
    
    func textInputView(textInputView: TextInputView, heightDidChange height: CGFloat) {
        // NOP
    }
    
    func textInputView(textInputView: TextInputView, sendButtonTapped sendButton: UIButton, gif: Gif?) {
        onTextSubmitted?(textInputView.text, selectedPartySize)
    }
    
    func textInputView(textInputView: TextInputView, giphyButtonTapped giphyButton: UIButton) {
        // NOP
    }
}
