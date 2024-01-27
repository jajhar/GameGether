//
//  GiphySearchViewController.swift
//  GameGether
//
//  Created by James Ajhar on 1/17/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import GiphyCoreSDK

class GiphySearchViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var collectionView: GiphySearchCollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchTextContainerView: UIView!
    @IBOutlet weak var searchTextContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchField: UITextField!
    
    // MARK: Properties
    var query: String?
    var onGifSelected: ((GiphyReaction) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboardWhenBackgroundTapped()
        styleUI()
        searchField.delegate = self
        searchField.placeholder = "search for gifs"
        
        collectionView.onGifSelected = onGifSelected
        
        if let query = query {
            // A query was already defined. Display it now with no search capabilities.
            collectionView.search(forGifsWithQuery: query)
            titleLabel.text = query
            searchTextContainerView.isHidden = true
        } else {
            // No query defined. Allow the user to search on their own.
            searchTextContainerView.becomeFirstResponder()
            titleLabel.text = "recent shares"
            collectionView.currentDataSource = .recentlyShared
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func styleUI() {
        titleLabel.font = AppConstants.Fonts.robotoMedium(17).font
        titleLabel.textColor = UIColor(hexString: "#bdbdbd")
    }

    // MARK: Interface Actions
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .giphyCloseButtonTapped)
        searchField.resignFirstResponder()  // Make sure keyboard is dismissed
        dismissSelf()
    }
    
    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo else { return }
        
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let endFrameY = endFrame.origin.y
        let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
        
        if endFrameY >= UIScreen.main.bounds.size.height {
            self.searchTextContainerBottomConstraint?.constant = 0.0
        } else {
            let offset: CGFloat = UIDevice.current.hasNotch ? 35 : 0
            self.searchTextContainerBottomConstraint?.constant = endFrame.size.height - offset
        }
        
        UIView.animate(withDuration: duration,
                       delay: TimeInterval(0),
                       options: animationCurve,
                       animations: { self.view.layoutIfNeeded() },
                       completion: nil)
    }

}

extension GiphySearchViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == searchField, let text = textField.text {
            query = text
            collectionView.search(forGifsWithQuery: text)
            titleLabel.text = text
        }

        return true
    }
}
