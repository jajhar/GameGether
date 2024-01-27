//
//  ResetPasswordViewController.swift
//  GameGether
//
//  Created by James Ajhar on 7/15/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD

class ResetPasswordViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var keyboardScrollView: KeyboardScrollView!
    @IBOutlet weak var passwordField: PasswordFormField!
    @IBOutlet weak var fieldView: UIView!
    
    // MARK: Properties
    var onPasswordUpdated: (() -> Void)?
    var successMessage: String? = "Your password has been updated. Please log in."
    
    override func viewDidLoad() {
        super.viewDidLoad()

        keyboardScrollView.keyboardDelegate = self
        passwordField.delegate = self
        passwordField.formDelegate = self
        
        _ = passwordField.becomeFirstResponder()
        
//        fieldView.addDropShadow(color: .black, radius: 1.0)
        confirmButton.addDropShadow(color: .black, radius: 1.0)
        
        validateFields()
        
        hideKeyboardWhenBackgroundTapped()
    }
    
    func validateFields() {
        if passwordField.isValid {
            confirmButton.alpha = 1.0
        } else {
            confirmButton.alpha = 0.6
        }
    }
    
    // MARK: Interface Actions
    
    @IBAction func confirmButtonPressed(_ sender: UIButton) {
        
        guard passwordField.isValid, let newPassword = passwordField.text else {
            return
        }
        
        AnalyticsManager.track(event: .resetPasswordConfirmPressed, withParameters: nil)

        HUD.show(.progress)

        DataCoordinator.shared.resetPassword(newPassword: newPassword) { [weak self] (error) in
            performOnMainThread {
                
                HUD.hide()
                
                guard error == nil else {
                    self?.presentGenericErrorAlert()
                    return
                }
                
                if let msg = self?.successMessage {
                    self?.presentGenericAlert(title: "Success!",
                                              message: msg)
                }
                
                self?.onPasswordUpdated?()
            }
        }
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .resetPasswordBackPressed, withParameters: nil)
        navigationController?.popViewController(animated: true)
    }
}

extension ResetPasswordViewController: KeyboardScrollViewDelegate {
    
    func keyboardScrollViewDidAdjustInsets(scrollView: UIScrollView) {
        
        var frame: CGRect?
        if passwordField.isFirstResponder {
            frame = passwordField.frame
        }
        
        guard let textFieldFrame = frame else { return }
        
        let rect = view.convert(textFieldFrame, from: view)
        scrollView.scrollRectToVisible(rect, animated: true)
    }
}

extension ResetPasswordViewController: UITextFieldDelegate, FormFieldValidationDelegate {
    
    func formTextField(field: FormTextField, didFailValidationForRules rules: [FormRule]) {
        // NOP
    }
    
    func formTextFieldTextDidChange(field: FormTextField) {
        field.validate()
        validateFields()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let formField = textField as? FormTextField {
            _ = formField.validate()
        }
        validateFields()
    }
}
