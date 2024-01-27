//
//  BirthdayPickerViewController.swift
//  GameGether
//
//  Created by James Ajhar on 6/24/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD

class BirthdayPickerViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var birthdayField: DateFormField! {
        didSet {
            birthdayField.addDropShadow(color: .black, opacity: 0.11, offset: CGSize(width: 1, height: 2), radius: 2.0)
            birthdayField.barButtonTitle = "Continue & Accept"
        }
    }
    
    @IBOutlet weak var privacyTextView: UITextView!
    @IBOutlet weak var fadedView: UIView!
    @IBOutlet weak var underageNoticeView: UIView!
    @IBOutlet weak var fieldView: UIView!
    @IBOutlet weak var fieldTitleLabel: UILabel!
    @IBOutlet weak var fieldSubtitleLabel: UILabel!
    @IBOutlet weak var noticeLabel: UILabel!
    @IBOutlet weak var noticeButton: UIButton!
    
    // MARK: Properties
    
    override func viewDidLoad() {
        super.viewDidLoad()

        birthdayField.dateFormDelegate = self
        birthdayField.text = Date().monthDayYearFormat()
        underageNoticeView.isHidden = true
        fadedView.isHidden = true
        
        let attributedString = NSMutableAttributedString(string: "by tapping continue & accept below, you acknowledge that you have read the privacy policy and agree to the terms of service")
        attributedString.addAttribute(.font, value: AppConstants.Fonts.robotoRegular(12.0).font, range: attributedString.fullRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor(red: 189/255.0, green: 189/255.0, blue: 189/255.0, alpha: 1.0), range: attributedString.fullRange)
        
        _ = attributedString.addLink(toText: "privacy policy", linkURL: "http://www.gamegether.com/privacy")
        _ = attributedString.addLink(toText: "terms of service", linkURL: "http://www.gamegether.com/tos")

        privacyTextView.attributedText = attributedString
        privacyTextView.textAlignment = .center
        
        styleUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        _ = birthdayField.becomeFirstResponder()
    }
    
    private func styleUI() {
        fieldTitleLabel.font = AppConstants.Fonts.robotoRegular(16).font
        fieldSubtitleLabel.font = AppConstants.Fonts.robotoRegular(12).font
        birthdayField.font = AppConstants.Fonts.robotoMedium(14).font
        privacyTextView.font = AppConstants.Fonts.twCenMTRegular(12).font
        noticeLabel.font = AppConstants.Fonts.robotoMedium(16).font
        noticeButton.titleLabel?.font = AppConstants.Fonts.robotoRegular(14).font
    }
    
    func presentNoticeView() {
        fadedView.isHidden = false
        underageNoticeView.isHidden = false
    }
    
    private func registerUser() {
  
        guard let localUser = DataCoordinator.shared.signedInUser else {
            GGLog.debug("No saved local user found or missing Facebook email, cannot proceed.")
            presentGenericErrorAlert()
            return
        }

        HUD.show(.labeledProgress(title: "please wait", subtitle: "we're setting up your account"))
        
        DataCoordinator.shared.register(user: localUser)
        { [weak self] (user, error) in
            
            guard let weakSelf = self else { return }
            
            performOnMainThread {
                HUD.hide()
                
                guard error == nil else {
                    
                    if let error = error as? RemoteError, error.errorCode == 409 {
                        weakSelf.presentGenericErrorAlert(message: error.localizedDescription)
                    } else {
                        weakSelf.presentGenericErrorAlert(message: error?.localizedDescription ?? "Something went wrong! Please try again.")
                    }
                    
                    return
                }
                
                AnalyticsManager.track(event: .createAccountSuccess, withParameters: nil)
                
                NavigationManager.shared.showMainView()
            }
        }
    }
    
    // MARK: Interface Actions
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .birthdayBackButtonPressed, withParameters: nil)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func noticeViewOkayButtonPressed(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
}

extension BirthdayPickerViewController: DateFormFieldDelegate {
    
    func dateFormField(dateField: DateFormField, doneButtonPressed date: Date) {
        
        guard let minAgeDate = Date().subtractYears(13) else {
            presentGenericErrorAlert()
            return
        }
        
        guard date < minAgeDate else {
            // User is not old enough to use the app. stop here...
            AnalyticsManager.track(event: .birthdayNextButtonPressed, withParameters: ["Ineligible": true])
            presentNoticeView()
            return
        }
        
        AnalyticsManager.track(event: .birthdayNextButtonPressed, withParameters: ["birthday": date])

        DataCoordinator.shared.updateLocalUser(withBirthday: date) { [weak self] (user, error) in
            
            guard let weakSelf = self else { return }
            
            if error != nil {
                GGLog.error("\(String(describing: error?.localizedDescription))")
            }
            
            performOnMainThread {
                weakSelf.registerUser()
            }
        }
    }
}

extension BirthdayPickerViewController: UITextViewDelegate {

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return false
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return true
    }
}
