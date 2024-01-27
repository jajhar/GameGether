//
//  RegisterUserViewController.swift
//  GameGether
//
//  Created by James Ajhar on 6/24/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn
import AuthenticationServices
import KeychainSwift

class RegisterUserViewController: UIViewController {

    enum RegisterViewControllerState {
        case newUser
        case existingUser
    }
    
    // MARK: Outlets
    @IBOutlet weak var loginProvidersStackView: UIStackView!
    @IBOutlet weak var signInWithAppleView: UIView!
    @IBOutlet weak var scrollView: KeyboardScrollView!
    @IBOutlet weak var facebookButtonContainerView: UIView!
    @IBOutlet weak var googleContainerView: UIView!
    
    @IBOutlet weak var exitButton: UIButton! {
        didSet {
            exitButton.addDropShadow(color: .black, opacity: 0.33, offset: CGSize(width: 1, height: 5), radius: 5)
        }
    }
    
    @IBOutlet weak var sectionBarView: SectionBarView! {
        didSet {
            sectionBarView.delegate = self
            sectionBarView.refreshView()
        }
    }
    
    // MARK: Properties
    
    public var state: RegisterViewControllerState = .newUser {
        didSet {
            guard isViewLoaded else { return }
            updateState()
        }
    }
    
    lazy var facebookLoginButton: FBLoginButton = {
        let button = FBLoginButton(frame: .zero)
        button.permissions = ["email", "public_profile"]
        button.delegate = self
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboardWhenBackgroundTapped()
        
        disableDarkMode()
        
        // Add Google login
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().presentingViewController = self

        styleUI()
        updateState()
        
        // Show the sign in with apple button if ios 13 or higher
        if #available(iOS 13.0, *) {
            signInWithAppleView.isHidden = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 13.0, *) {
            performExistingAccountSetupFlows()
        }
    }

    private func styleUI() {
        facebookButtonContainerView.addDropShadow(color: .black, opacity: 0.11, offset: CGSize(width: 0, height: 2), radius: 2.0)
        googleContainerView.addDropShadow(color: .black, opacity: 0.11, offset: CGSize(width: 1, height: 2), radius: 2.0)
        signInWithAppleView.addDropShadow(color: .black, opacity: 0.11, offset: CGSize(width: 1, height: 2), radius: 2.0)
    }
    
    private func updateState() {
        sectionBarView.refreshView()
        view.layoutIfNeeded()
    }
    
    // MARK: Interface Actions
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .registerBackButtonPressed, withParameters: nil)
        dismissSelf()
    }
    
    @IBAction func googleLoginButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .onboardingGoogleSignInPressed)
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    @IBAction func facebookLoginButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .onboardingFacebookSignInPressed)
        facebookLoginButton.sendActions(for: .touchUpInside)
    }
    
    @available(iOS 13.0, *)
    @IBAction func signInWithAppleButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .onboardingAppleSignInPressed)

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    @IBAction func stateButtonPressed(_ sender: UIButton) {
        switch state {
        case .existingUser:
            state = .newUser
        case .newUser:
            state = .existingUser
        }
    }
        
    fileprivate func moveToNextStep() {
        let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: SelectGamerTagViewController.storyboardIdentifier)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func exitButtonPressed(_ sender: Any) {
        dismissSelf()
    }
}

extension RegisterUserViewController: LoginButtonDelegate {
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // NOP
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        
        
        if let error = error {
            GGLog.error("\(error.localizedDescription)")
            presentGenericErrorAlert()
            return
        }
        
        guard let token = AccessToken.current?.tokenString else {
            GGLog.debug("\(#function) Missing token string")
            return
        }
        
        HUD.show(.progress)
        
        GraphRequest(graphPath: "me",
                          parameters: ["fields": "email"]).start(completionHandler:
                            { [weak self] (connection, result, error) in
                                
                                guard let weakSelf = self else { return }
                                
                                LoginManager().logOut()
                                
                                guard error == nil else {
                                    performOnMainThread {
                                        weakSelf.presentGenericErrorAlert()
                                    }
                                    return
                                }
                                
                                guard let json = result as? JSONDictionary,
                                    let facebookEmail = json["email"] as? String else {
                                        // Failed to get email from response
                                        performOnMainThread {
                                            HUD.hide()
                                            weakSelf.presentGenericErrorAlert(message: "An email address is required to sign in. Please update your Facebook account to include an email address and try again.")
                                        }
                                        return
                                }
                                
                                // First attempt to log in the user in case they already exist
                                DataCoordinator.shared.loginUser(withFacebookToken: token) { [weak self] (user, error) in
                                    
                                    guard let weakSelf = self else { return }
                                    
                                    performOnMainThread {
                                        HUD.hide()
                                        
                                        guard error == nil else {
                                            
                                            if let error = error as? RemoteError, error.errorCode == 404 {
                                                // User does not yet exist. Kick them into the registration flow.
                                                // We do not want to show the email/password flow of our onboarding process in this case because we are creating
                                                //  a user through their Facebook credentials.
                                                DataCoordinator.shared.createLocalUser(withEmail: facebookEmail, completion: { (user, error) in
                                                    
                                                    performOnMainThread {
                                                        guard user != nil else {
                                                            weakSelf.presentGenericErrorAlert()
                                                            return
                                                        }
                                                        
                                                        let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: SelectGamerTagViewController.storyboardIdentifier)
                                                        weakSelf.navigationController?.pushViewController(viewController, animated: true)
                                                    }
                                                })
                                                
                                            } else if let error = error as? RemoteError, error.errorCode == 400 {
                                                weakSelf.presentGenericErrorAlert(message: error.localizedDescription)
                                                
                                            } else {
                                                weakSelf.presentGenericErrorAlert()
                                            }
                                            return
                                        }
                                        
                                        GGLog.debug("Login Success!")
                                        NavigationManager.shared.showMainView()
                                    }
                                }
                          })
    }
}

extension RegisterUserViewController: GIDSignInDelegate {
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        if let error = error {
            GGLog.error("\(error.localizedDescription)")
            if error._code != -5 {
                // -5 signals the user canceled the sign-in flow on their own.
                presentGenericErrorAlert()
            }
            return
        }
        
        guard let idToken = user.authentication.idToken else {
            GGLog.debug("Missing token string")
            presentGenericErrorAlert()
            return
        }
        
        guard let email = user.profile.email else {
            GGLog.debug("Missing email string")
            presentGenericErrorAlert(message: "An email address is required to sign in. Please update your Google account to include an email address and try again.")
            return
        }
        
        HUD.show(.progress)
        
        // First attempt to log in the user in case they already exist
        DataCoordinator.shared.loginUser(withGoogleToken: idToken) { [weak self] (user, error) in
            
            guard let weakSelf = self else { return }
            
            performOnMainThread {
                HUD.hide()
                
                guard error == nil else {
                    
                    if let error = error as? RemoteError, error.errorCode == 404 {
                        // User does not yet exist. Kick them into the registration flow.
                        // We do not want to show the email/password flow of our onboarding process in this case because we are creating
                        //  a user through their Facebook credentials.
                        DataCoordinator.shared.createLocalUser(withEmail: email, completion: { (user, error) in
                            
                            performOnMainThread {
                                guard user != nil else {
                                    weakSelf.presentGenericErrorAlert()
                                    return
                                }
                                
                                let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: SelectGamerTagViewController.storyboardIdentifier)
                                weakSelf.navigationController?.pushViewController(viewController, animated: true)
                            }
                        })
                        
                    } else if let error = error as? RemoteError, error.errorCode == 400 {
                        weakSelf.presentGenericErrorAlert(message: error.localizedDescription)
                        
                    } else {
                        weakSelf.presentGenericErrorAlert()
                    }
                    return
                }
                
                GGLog.debug("Login Success!")
                NavigationManager.shared.showMainView()
            }
        }
    }
}

extension RegisterUserViewController: SectionBarViewDelegate {
    
    func sectionBarView(view: SectionBarView, titleForTabAt index: Int) -> String {
        return "Log into your account"
    }
    
    func sectionBarView(view: SectionBarView, didSelectTabAt index: Int) {
        // NOP
    }
}

@available(iOS 13.0, *)
extension RegisterUserViewController: ASAuthorizationControllerDelegate {
    
    // MARK: - Sign in with Apple

    /// Prompts the user if an existing iCloud Keychain credential or Apple ID credential is found.
    func performExistingAccountSetupFlows() {
        // Prepare requests for Apple ID provider.
        let requests = [ASAuthorizationAppleIDProvider().createRequest(),
                        ASAuthorizationPasswordProvider().createRequest()]

        // Create an authorization controller with the given requests.
        let authorizationController = ASAuthorizationController(authorizationRequests: requests)
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        var userId: String?
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            userId = appleIDCredential.user
            
        } else if let passwordCredential = authorization.credential as? ASPasswordCredential {
            // Sign in using an existing iCloud Keychain credential.
            userId = passwordCredential.user
        }
        
        guard let appleUserId = userId else {
            performOnMainThread {
                self.presentGenericErrorAlert(message: "Failed to authenticate with Apple!")
            }
            return
        }
        
        KeychainSwift().set(appleUserId, forKey: AppConstants.Keychain.appleUserIdentifier)
        
        // First attempt to log in the user in case they already exist
        DataCoordinator.shared.loginUser(withAppleUserId: appleUserId) { [weak self] (user, error) in
            
            guard let weakSelf = self else { return }
            
            performOnMainThread {
                HUD.hide()
                
                guard error == nil else {
                    
                    if let error = error as? RemoteError, error.errorCode == 404 {
                        // User does not yet exist. Kick them into the registration flow.
                        // We do not want to show the email/password flow of our onboarding process in this case because we are creating
                        //  a user through their Apple credentials.
                        DataCoordinator.shared.createLocalUser(withEmail: "", completion: { (user, error) in
                            
                            performOnMainThread {
                                guard user != nil else {
                                    weakSelf.presentGenericErrorAlert()
                                    return
                                }
                                
                                let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: SelectGamerTagViewController.storyboardIdentifier)
                                weakSelf.navigationController?.pushViewController(viewController, animated: true)
                            }
                        })
                        
                    } else if let error = error as? RemoteError, error.errorCode == 400 {
                        weakSelf.presentGenericErrorAlert(message: error.localizedDescription)
                        
                    } else {
                        weakSelf.presentGenericErrorAlert()
                    }
                    return
                }
                
                GGLog.debug("Login Success!")
                NavigationManager.shared.showMainView()
            }
        }
    }

    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
    }
}

@available(iOS 13.0, *)
extension RegisterUserViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
