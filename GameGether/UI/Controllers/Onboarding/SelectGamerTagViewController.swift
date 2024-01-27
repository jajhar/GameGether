//
//  SelectGamerTagViewController.swift
//  GameGether
//
//  Created by James Ajhar on 6/21/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD

class SelectGamerTagViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var fieldTitleLabel: UILabel!
    @IBOutlet weak var delayedSearchTextField: GamerTagSearchTextField! {
        didSet {
            delayedSearchTextField.textAlignment = .left
        }
    }
    
    @IBOutlet weak var countLabel: UILabel!
    
    @IBOutlet weak var errorLabel: UILabel! {
        didSet {
            errorLabel.text = "Your gg username must be under 20 characters.\nit cannot have a :, /, @, or space as a character."
        }
    }
    
    @IBOutlet weak var fieldView: UIView!
    
    @IBOutlet weak var avatarButton: UIButton! {
        didSet {
            avatarButton.imageView?.contentMode = .scaleAspectFill
        }
    }
    
    @IBOutlet weak var doneButton: UIButton!
    
    @IBOutlet weak var initialsLabel: UILabel! {
        didSet {
            initialsLabel.font = AppConstants.Fonts.robotoRegular(30).font
        }
    }
    
    @IBOutlet weak var profilePicsTitleLabel: UILabel!
    @IBOutlet weak var profilePicsCollectionView: ProfilePicsCollectionView! {
        didSet {
            profilePicsCollectionView.profilePicCollectionDelegate = self
        }
    }
    
    // MARK: Properties
    
    private let imagePicker = UIImagePickerController()
    private var pickedImage: UIImage?
    private var defaultImageURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        delayedSearchTextField.searchDelegate = self
        _ = delayedSearchTextField.becomeFirstResponder()
        
        imagePicker.delegate = self

        // pick a random default profile pic
        let random = Int.random(in: 0 ..< ProfilePicsCollectionView.Constants.profilePics.count)
        let defaultImage = ProfilePicsCollectionView.Constants.profilePics[random]
        defaultImageURL = defaultImage
        avatarButton.sd_setImage(with: defaultImage, for: .normal, completed: nil)

        toggleDoneButton(enabled: false)

        styleUI()
    }

    private func styleUI() {
        fieldTitleLabel.font = AppConstants.Fonts.robotoMedium(16).font
        delayedSearchTextField.font = AppConstants.Fonts.robotoRegular(14).font
        countLabel.font = AppConstants.Fonts.twCenMTRegular(11).font
        countLabel.textColor = UIColor(hexString: "#BDBDBD")
        errorLabel.font = AppConstants.Fonts.twCenMTRegular(11).font
        
        delayedSearchTextField.addDropShadow(color: .black, opacity: 0.11, offset: CGSize(width: 1, height: 2), radius: 2.0)
    }
    
    private func toggleDoneButton(enabled: Bool) {
        doneButton.isEnabled = enabled
        doneButton.alpha = enabled ? 1.0 : 0.6
    }

    // MARK: Interface Actions
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .selectIGNBackButtonPressed, withParameters: nil)
        dismissSelf()
    }

    @IBAction func doneButtonPressed() {

        guard let ign = delayedSearchTextField.text else { return }
        
        // Remove the count text from the right of the IGN
        let strippedIGN = stripIGN(ign: ign)
       
        guard !strippedIGN.isEmpty else { return }
        
        HUD.show(.progress)

        uploadImage { [weak self] (imageURL, error) in
            guard error == nil else {
                performOnMainThread {
                    HUD.flash(.error, delay: 1.0)
                }
                return
            }
            
            DataCoordinator.shared.updateLocalUser(withIGN: strippedIGN, profileImageURL: imageURL, profileImageColoredBackgroundURL: self?.defaultImageURL) { (localUser, error) in
                
                performOnMainThread {
                    guard error == nil else {
                        HUD.flash(.error, delay: 1.0)
                        self?.presentGenericErrorAlert()
                        return
                    }
                    
                    HUD.hide()
                    
                    AnalyticsManager.track(event: .selectIGNNextButtonPressed, withParameters: nil)
                    
                    let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: BirthdayPickerViewController.storyboardIdentifier)
                    self?.navigationController?.pushViewController(viewController, animated: true)

                }
            }
        }
    }
    
    private func uploadImage(_ completion: @escaping (URL?, Error?) -> Void) {
        guard let pickedImage = pickedImage else {
            completion(nil, nil)
            return
        }
        
        guard let imageData = pickedImage.jpegRepresentation() else {
            GGLog.error("Failed to convert image to jpeg representation.")
            completion(nil, nil)
            return
        }
        
        DataCoordinator.shared.s3Uploader.upload(data: imageData,
                                                 contentType: .image,
                                                 progress:
            { (task, progress) in
                GGLog.debug("Upload Progress: \(progress)")
                
        }) { (url, error) in
            performOnMainThread {
                
                guard error == nil, let url = url else {
                    GGLog.error("Upload Failed: \(String(describing: error?.localizedDescription))")
                    completion(nil, error)
                    return
                }
                
                completion(url, nil)
            }
        }
    }
    
    @IBAction func avatarButtonPressed(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            presentGenericAlert(title: "Access Denied", message: "You must allow the app to access your photo library in order to upload a photo. Please go to Settings->Privacy->Photos and allow GameGether to access your photo library.")
            return
        }
        
        AnalyticsManager.track(event: .onboardingUploadProfilePicPressed)
        
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    /// Call to strip away the count text from an IGN string
    ///
    /// - Parameter ign: The ign to strip
    /// - Returns: the ign without count text
    func stripIGN(ign: String) -> String {
        let ignWithCount = ign.components(separatedBy: " ")
        return ignWithCount.first ?? ""
    }
    
}

extension SelectGamerTagViewController: GamerTagSearchTextFieldDelegate {

    func gamerTagSearchTextField(textField: GamerTagSearchTextField, didUpdateText text: String?) {
        
        errorLabel.isHidden = true
        countLabel.text = ""

        initialsLabel.text = "\(textField.text?.prefix(2) ?? "")".uppercased()
        
        guard let text = text else { return }
        
        toggleDoneButton(enabled: !text.isEmpty && delayedSearchTextField.isValid)
        
        guard !text.isEmpty else { return }
        
        guard delayedSearchTextField.validate() else {
            errorLabel.isHidden = false
            return
        }
        
        DataCoordinator.shared.checkIGNAvailability(ign: text) { [weak self] (count, error) in
            
            guard error == nil else {
                GGLog.error("Failed to check IGN: \(String(describing: error))")
                return
            }
            
            GGLog.debug("IGN Count: \(count)")
            self?.countLabel.text = count == 0 ? "You’re the first with this gg username" : "\(count) user(s) have this gg username, you will be #\(count + 1)"
        }
    }
    
    func gamerTagSearchTextField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
}

// MARK: UIImagePickerControllerDelegate

extension SelectGamerTagViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        
        if let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage {
            pickedImage = UIImage.imageWithImage(sourceImage: image, scaledToWidth: 300)
            avatarButton.setImage(pickedImage, for: .normal)
            initialsLabel.isHidden = true
            profilePicsTitleLabel.isHidden = true
            profilePicsCollectionView.isHidden = true
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}

extension SelectGamerTagViewController: ProfilePicsCollectionViewDelegate {
    
    func profilePicCollectionView(_ collectionView: ProfilePicsCollectionView, didSelectProfilePic imageURL: URL) {
        avatarButton.sd_setImage(with: imageURL, for: .normal, completed: nil)
        pickedImage = nil
        initialsLabel.isHidden = false
        defaultImageURL = imageURL
        AnalyticsManager.track(event: .profileBackgroundColorSelected, withParameters: [
            "image": imageURL.absoluteString
            ])
    }
}
