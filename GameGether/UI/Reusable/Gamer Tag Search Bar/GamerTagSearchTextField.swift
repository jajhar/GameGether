//
//  DelayedSearchBar.swift
//  GameGether
//
//  Created by James Ajhar on 6/21/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

protocol GamerTagSearchTextFieldDelegate: class {
    func gamerTagSearchTextField(textField: GamerTagSearchTextField, didUpdateText text: String?)
    func gamerTagSearchTextField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
}

class GamerTagSearchTextField: FormTextField, UITextFieldDelegate {

    fileprivate var searchTimer: Timer?

    var autoCompleteCharacterCount = 0
    var delay: Double = 0.5
    var maxCharCount = 20
    weak var searchDelegate: GamerTagSearchTextFieldDelegate?
    
    override func commonInit() {
        delegate = self
        
        showsErrorBorder = true

        addClearTextButton()
        let acceptableCharsRule = CustomFormRule(message: "Unacceptable characters in gamer tag.",
                                                 regex: "^[^@:!/]+$",
                                                   isRequired: true)
        ruleSet.append(acceptableCharsRule)
    }
    
    override func updateUI() {
        if text?.isEmpty == false {
            addRightButton()
        } else {
            rightView = nil
        }
    }
    
    deinit {
        searchTimer?.invalidate()
    }
    
    @objc override func clearTextPressed(sender: UIButton) {
        resetValues()
    }
    
    func formatSubstring(subString: String) -> String {
        let formatted = String(subString.dropLast(autoCompleteCharacterCount))
        return formatted
    }
    
    private func resetValues() {
        autoCompleteCharacterCount = 0
        text = ""
        searchDelegate?.gamerTagSearchTextField(textField: self, didUpdateText: text)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }

        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)

        guard updatedText.count < maxCharCount,
            string.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
            return false
        }
        
        searchTimer?.invalidate()  // Cancel any previous timer
        // …schedule a timer for a given delay
        searchTimer = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(performSearch), userInfo: nil, repeats: false)
        
        return searchDelegate?.gamerTagSearchTextField(textField, shouldChangeCharactersIn: range, replacementString: string) ?? true
    }
        
    @objc func performSearch() {
        searchTimer?.invalidate()
        searchDelegate?.gamerTagSearchTextField(textField: self, didUpdateText: text)
    }

}
