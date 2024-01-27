//
//  FormTextField.swift
//  GameGether
//
//  Created by James Ajhar on 6/21/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

public protocol FormFieldValidationDelegate: class {
    func formTextField(field: FormTextField, didFailValidationForRules rules: [FormRule])
    func formTextFieldTextDidChange(field: FormTextField)
}

open class FormTextField: UITextField {

    // MARK: Properties
    public var titleLabel: UILabel!
    public var rightButton: UIButton!

    public weak var formDelegate: FormFieldValidationDelegate?
    public var ruleSet: [FormRule] = [FormRule]()
    public var errorIconIsShown = false
    
    // The max amount of rules that are allowed to fail for the field to be considered "valid".
    //  Default is none of them
    public var maximumAllowedFailedRules: Int = 0
    
    public var isValid: Bool {
        return checkValidation()
    }
    
    internal var originalTextColor: UIColor?
    
    override open var text: String? {
        didSet {
            updateUI()
        }
    }
    
    /// https://stackoverflow.com/questions/7305538/uitextfield-with-secure-entry-always-getting-cleared-before-editing
    override open var isSecureTextEntry: Bool {
        didSet {
            if isFirstResponder {
                _ = becomeFirstResponder()
            }
        }
    }
    
    /// Overriding this to prevent secure text entry from deleting all text within the field when the user begins typing
    override open func becomeFirstResponder() -> Bool {
        let success = super.becomeFirstResponder()
        
        if isSecureTextEntry, let text = self.text {
            // deleteBackward() doesn't work when cursor is in the middle of the text
            self.text = ""
            insertText(text)
        }
        
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)

        return success
    }
    
    /// Fix for jumping text when tapping out of text field
    ///  https://stackoverflow.com/questions/32765372/uitextfield-text-jumps
    override open func resignFirstResponder() -> Bool {
        let success = super.resignFirstResponder()
        
        removeTarget(self, action: #selector(textDidChange), for: .editingChanged)

        layoutIfNeeded()
        return success
    }

    var showsRightButton: Bool = false {
        didSet {
            updateUI()
        }
    }

    public var leftPadding: CGFloat = 10 {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }  // Used to inset the leftView

    public var rightPadding: CGFloat = 10 {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }  // Used to inset the rightView

    var showsErrorBorder: Bool = false {
        didSet {
            originalTextColor = textColor
            updateUI()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func addClearTextButton() {
        rightButton = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 30))
        rightButton.isAccessibilityElement = true
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.contentHorizontalAlignment = .right
        rightButton.setImage(#imageLiteral(resourceName: "RemoveType"), for: .normal)
        rightButton.addTarget(self,
                              action: #selector(clearTextPressed(sender:)),
                              for: .touchUpInside)
        showsRightButton = true
    }
    
    @objc func clearTextPressed(sender: UIButton) {
        text = ""
    }

    func commonInit() {
        // Setup Form Field accessory views
        leftViewMode = .always

        // Title Label
        titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 85, height: 30))
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = true
        titleLabel.text = ""
        titleLabel.textColor = .lightGray
        titleLabel.isAccessibilityElement = true
        
        setTitleLabel(hidden: true)
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()

        leftView = titleLabel
        layoutIfNeeded()
    }

    internal func updateRightButton() {
        guard showsRightButton else { return }
        
        if text?.isEmpty == false {
            addRightButton()
        } else {
            rightView = nil
        }
    }

    @objc open func textDidChange() {
        updateRightButton()
        formDelegate?.formTextFieldTextDidChange(field: self)
    }

    // Add padding to right view
    override open func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.rightViewRect(forBounds: bounds)
        rect.origin.x = bounds.size.width - rect.size.width - rightPadding
        rect.origin.y = 0
        rect.size.height = bounds.size.height
        return rect
    }

    // Add padding to left view
    override open func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.leftViewRect(forBounds: bounds)
        rect.origin.x = leftPadding
        rect.origin.y = 0
        rect.size.height = bounds.size.height
        return rect
    }

    // Toggle the rightView button
    internal func addRightButton() {
        guard rightView != rightButton else { return }

        if rightButton.superview != nil { rightButton.removeFromSuperview() }
        addSubview(rightButton)

        rightView = rightButton
        rightViewMode = .always

        rightButton.constrainTo(edges: .bottom, .top, .right)
    }

    func toggleErrorMode(show: Bool) {
        guard showsErrorBorder else {
            return
        }

        if show {
            layer.borderWidth = 2.0
            textColor = AppConstants.Colors.textFieldErrorBorder.color
            layer.borderColor = AppConstants.Colors.textFieldErrorBorder.color.cgColor
            layer.cornerRadius = 5.0
        } else {
            layer.borderWidth = 0.0
            layer.cornerRadius = 0.0
            layer.borderColor = UIColor.black.cgColor
            textColor = originalTextColor
        }
        
        layoutIfNeeded()
    }

    func setTitleLabel(hidden: Bool) {
        titleLabel.isHidden = hidden

        if hidden {
            leftViewMode = .never
            leftView = nil
        } else {
            leftViewMode = .always
            leftView = titleLabel
        }
    }

    @objc internal func rightButtonPressed(sender: UIButton) {
        updateRightButton()
    }

    internal func updateUI() {

        if showsRightButton {
            addRightButton()
            return
        }

        rightView = nil
    }

    internal func checkValidation() -> Bool {
        guard let text = text else { return false }

        var failedRules: Int = 0
        
        for rule in ruleSet {
            if !rule.validate(text) {
                
                if rule.isRequired {
                    // If rule is ABSOLUTELY required, stop here and fail
                    return false
                }
                
                failedRules += 1
            }
        }
        
        if failedRules > maximumAllowedFailedRules {
            return false
        }

        return true
    }
    
    public func failingRules() -> [FormRule] {
        
        guard let text = text else { return [] }
        
        var failedRules = [FormRule]()
        
        for rule in self.ruleSet {
            if !rule.validate(text) {
                failedRules.append(rule)
            }
        }
        
        return failedRules
    }

    @discardableResult
    public func validate() -> Bool {
        guard let text = text else { return false }

        var success: Bool = true
        var failedRules = [FormRule]()

        for rule in ruleSet {
            if !rule.validate(text) {
                failedRules.append(rule)
                success = false
            }
        }

        if failedRules.count <= maximumAllowedFailedRules,
            failedRules.filter({ $0.isRequired }).isEmpty {
            success = true
        }
        
        if !success {
            toggleErrorMode(show: true)
            formDelegate?.formTextField(field: self, didFailValidationForRules: failedRules)
        } else {
            toggleErrorMode(show: false)
        }

        return success
    }
}
