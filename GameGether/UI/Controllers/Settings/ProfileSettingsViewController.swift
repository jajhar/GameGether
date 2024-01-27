//
//  ProfileSettingsViewController.swift
//  GameGether
//
//  Created by James Ajhar on 9/21/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import SafariServices
import MessageUI

class ProfileSettingsViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var logoutView: UIView!
    @IBOutlet weak var changePasswordView: UIView!
    @IBOutlet weak var privacyView: UIView!
    @IBOutlet weak var aboutView: UIView!
    @IBOutlet weak var appVersionLabel: UILabel!
    
    // MARK: Properties
    
    override func viewDidLoad() {
        super.viewDidLoad()

        logoutView.layer.cornerRadius = 27.5
        changePasswordView.layer.cornerRadius = 27.5
        privacyView.layer.cornerRadius = 27.5
        aboutView.layer.cornerRadius = 27.5
        
        appVersionLabel.text = "v\(UIApplication.appVersion ?? "") (\(UIApplication.buildNumber ?? ""))"
    }
    
    // MARK: Interface Actions
    
    @IBAction func backButtonPressed(_ sender: Any) {
        dismissSelf()
    }
    
    @IBAction func aboutButtonPressed(_ sender: Any) {
        let vc = SFSafariViewController(url: APIRequest.aboutPageURL)
        vc.delegate = self
        present(vc, animated: true)
    }
    
    @IBAction func privacyButtonPressed(_ sender: Any) {
        let vc = SFSafariViewController(url: APIRequest.privacyPageURL)
        vc.delegate = self
        present(vc, animated: true)
    }
    
    @IBAction func changePasswordButtonPressed(_ sender: Any) {
        let viewController = UIStoryboard(name: AppConstants.Storyboards.resetPassword, bundle: nil).instantiateViewController(withIdentifier: ResetPasswordViewController.storyboardIdentifier) as! ResetPasswordViewController
        
        viewController.successMessage = nil
        viewController.onPasswordUpdated = { [weak self] in
            viewController.dismissSelf()
            self?.presentGenericAlert(title: "Success!", message: "Your password has been updated.")
        }
        
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func helpButtonPressed(_ sender: Any) {
        guard MFMailComposeViewController.canSendMail() else {
            presentGenericAlert(title: "Failed to send email", message: "We were unable to access your email client.")
            return
        }
        
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setToRecipients(["support@gamegether.com"])
        mail.setSubject("GG Help Request")
        mail.setMessageBody("<p>You're so awesome!</p>", isHTML: false)
        present(mail, animated: true)
    }
    
    @IBAction func logoutButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Wait!", message: "Are you sure you want to log out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "yes", style: .destructive, handler: { (action) in
            DataCoordinator.shared.logout()
        }))
        alert.addAction(UIAlertAction(title: "no", style: .cancel))
        alert.show()
    }
}

extension ProfileSettingsViewController: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismissSelf()
    }
}

extension ProfileSettingsViewController: MFMailComposeViewControllerDelegate {

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismissSelf()
    }
}
