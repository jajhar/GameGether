//
//  ForgotPasswordViewController.swift
//  GameGether
//
//  Created by James Ajhar on 7/10/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD

class ForgotPasswordViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var emailField: EmailFormField!
    @IBOutlet weak var keyboardScrollView: KeyboardScrollView!
    @IBOutlet weak var fieldView: UIView!
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var sectionBarView: SectionBarView! {
        didSet {
            sectionBarView.delegate = self
            sectionBarView.refreshView()
        }
    }
    
    // MARK: Properties

    override func viewDidLoad() {
        super.viewDidLoad()
        
        keyboardScrollView.keyboardDelegate = self
        emailField.delegate = self
        emailField.formDelegate = self
        
        _ = emailField.becomeFirstResponder()

        emailField.addDropShadow(color: .black, opacity: 0.11, offset: CGSize(width: 1, height: 2), radius: 2.0)
        sendButton.addDropShadow(color: .black, opacity: 0.11, offset: CGSize(width: 1, height: 2), radius: 2.0)

        validateFields()
        
        hideKeyboardWhenBackgroundTapped()
    }
    
    func validateFields() {
        if emailField.isValid {
            sendButton.alpha = 1.0
        } else {
            sendButton.alpha = 0.6
        }
    }
}

extension ForgotPasswordViewController {
    
    // MARK: Interface Actions
    
    @IBAction func forgotPasswordPressed(_ sender: UIButton) {
        guard emailField.isValid, let email = emailField.text else {
            return
        }
        
        AnalyticsManager.track(event: .forgotPasswordSendButtonPressed, withParameters: nil)

        HUD.show(.progress)

        DataCoordinator.shared.sendForgotPasswordEmail(toEmail: email) { [weak self] (error) in
            performOnMainThread {
                
                HUD.hide()

                guard error == nil else {
                    self?.presentGenericErrorAlert()
                    return
                }

                self?.presentGenericAlert(title: "Success!",
                                          message: "We've sent an e-mail to this address with instructions on how to reset your password. Can't find it? Be sure to check your spam folder as well.")
            }
        }
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .forgotPasswordBackButtonPressed, withParameters: nil)
        navigationController?.popViewController(animated: true)
    }
}

extension ForgotPasswordViewController: KeyboardScrollViewDelegate {
    
    func keyboardScrollViewDidAdjustInsets(scrollView: UIScrollView) {
        
        var frame: CGRect?
        if emailField.isFirstResponder {
            frame = emailField.frame
        }
        
        guard let textFieldFrame = frame else { return }
        
        let rect = view.convert(textFieldFrame, from: view)
        scrollView.scrollRectToVisible(rect, animated: true)
    }
}

extension ForgotPasswordViewController: UITextFieldDelegate, FormFieldValidationDelegate {
    
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

extension ForgotPasswordViewController: SectionBarViewDelegate {
    
    func sectionBarView(view: SectionBarView, titleForTabAt index: Int) -> String {
        return "let’s reset your password"
    }
    
    func sectionBarView(view: SectionBarView, didSelectTabAt index: Int) {
        // NOP
    }
}
