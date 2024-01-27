//
//  GamerTagsPopUpViewController.swift
//  GameGether
//
//  Created by James Ajhar on 12/18/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD

class PopOverBackgroundView: UIPopoverBackgroundView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.shadowRadius = 4
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.layer.shadowRadius = 4
    }
}

class GamerTagsPopUpViewController: UIViewController, ShowsNavigationOverlay {

    struct Constants {
        static let horizontalMargin: CGFloat = 18   // Per design docs
        static let verticalMargin: CGFloat = 13     // Per design docs
    }
    
    // MARK: UI
    
    lazy var gamerTagsStackView: UIStackView = {
        let stack = UIStackView(frame: .zero)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .leading
        stack.distribution = .fill
        stack.spacing = 0
        view.addSubview(stack)
        
        if popoverPresentationController == nil {
            // if this is not a popover presentation, constrain to superview.
            stack.constrainToSuperview()
        } else {
            // else this is a popover presentation style so give it some padding (per design docs)
            // We do NOT constrain to the bottom and right so that we can allow resizing based on whatever this stack view's dimensions come out to be after layout. (see setupStackView function)
            stack.constrainTo(edge: .top)?.constant = Constants.verticalMargin
            stack.constrainTo(edge: .left)?.constant = Constants.horizontalMargin
        }
        
        return stack
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppConstants.Fonts.robotoBold(14).font
        label.textColor = UIColor(hexString: "#57A2E1")
        label.text = "Games & Gamertag"
        label.constrainHeight(30)
        return label
    }()

    // MARK: Properties
    
    private weak var gamerTagTextField: UITextField?
    private var saveAction: UIAlertAction?

    private(set) var user: User? {
        didSet {
            titleLabel.text =  user?.isSignedInUser == true ? "Your Games" : "Games & Gamertag"
        }
    }
    
    private var games = [Game]()
    
    var onDidUpdate: (() -> Void)?

    var showDropShadow: Bool = true {
        didSet {
            if showDropShadow {
                view.addDropShadow(color: .black, opacity: 0.5, radius: 2)
            } else {
                view.addDropShadow(color: .clear, opacity: 0.0, radius: 0)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
    }
    
    func reload() {
        getLatestProfile()
    }
    
    func setupWithUser(_ user: User) {
        self.user = user
        getLatestProfile()
    }
    
    private func getLatestProfile() {
        guard let user = user else { return }
        
        DataCoordinator.shared.getProfile(forUser: user.identifier, allowCache: false) { [weak self] (updatedUserProfile, error) in
            guard let weakSelf = self, error == nil, let user = updatedUserProfile else {
                GGLog.error("Error: \(String(describing: error))")
                return
            }
            
            DataCoordinator.shared.getFavoriteGames { (signedInUsersGames, error) in
                guard error == nil else {
                    GGLog.error("Error: \(String(describing: error))")
                    return
                }

                performOnMainThread {
                    weakSelf.user = user
                    
                    let gamerTags: [GamerTag] = user.gamerTags.compactMap({
                        let game = $0.game
                        guard signedInUsersGames.contains(where: { $0.identifier == game?.identifier }) else { return nil } // ignore games not in common
                        return $0
                    })
                    
                    weakSelf.games = gamerTags.compactMap({
                        let usersGamerTag = $0
                        let game = usersGamerTag.game
                        game?.gamerTag = usersGamerTag.gamerTag ?? ""
                        return game
                    })
                    
                    weakSelf.setupStackView(withGamerTags: gamerTags)
                }
            }
        }
    }
    
    private func setupStackView(withGamerTags gamerTags: [GamerTag]) {
        guard let user = user else { return }

        _ = gamerTagsStackView.arrangedSubviews.compactMap({ $0.removeFromSuperview() })
        
        guard !gamerTags.isEmpty else { return }
        
        // Title + Edit button
        let titleStack = UIStackView(frame: .zero)
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        titleStack.axis = .horizontal
        titleStack.alignment = .center
        titleStack.distribution = .fill
        titleStack.spacing = 8
        titleStack.addArrangedSubview(titleLabel)
        
        gamerTagsStackView.addArrangedSubview(titleStack)

        for (index, gamerTag) in gamerTags.enumerated() {
            
            let horizontalStack = UIStackView(frame: .zero)
            horizontalStack.translatesAutoresizingMaskIntoConstraints = false
            horizontalStack.axis = .horizontal
            horizontalStack.alignment = .center
            horizontalStack.distribution = .fill
            horizontalStack.spacing = 8
        
            // Edit button
            let editButton = UIButton(frame: .zero)
            editButton.translatesAutoresizingMaskIntoConstraints = false
            editButton.setTitle("edit", for: .normal)
            editButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(14).font
            editButton.setTitleColor(UIColor(hexString: "#3399FF"), for: .normal)
            editButton.tag = index  // capture the index of the current gamer tag for use when we copy
            editButton.addTarget(self, action: #selector(editButtonPressed(button:)), for: .touchUpInside)

            // The game's title
            let gameLabel = UILabel(frame: .zero)
            gameLabel.translatesAutoresizingMaskIntoConstraints = false
            gameLabel.text = gamerTag.game?.title
            gameLabel.font = AppConstants.Fonts.robotoMedium(13).font
            gameLabel.textColor = UIColor(hexString: "#333333")
            horizontalStack.addArrangedSubview(gameLabel)

            // The user's gamertag
            if let gamerTag = gamerTag.gamerTag, !gamerTag.isEmpty {
                let ignButton = UIButton(frame: .zero)
                ignButton.translatesAutoresizingMaskIntoConstraints = false
                ignButton.setTitle(gamerTag, for: .normal)
                ignButton.setTitleColor(UIColor(hexString: "#BDBDBD"), for: .normal)
                ignButton.titleLabel?.font = AppConstants.Fonts.robotoRegular(13).font
                ignButton.tag = index  // capture the index of the current gamer tag for use when we copy
                horizontalStack.addArrangedSubview(ignButton)

                if !user.isSignedInUser {
                    // Copy gamer tag button
                    ignButton.addTarget(self, action: #selector(copyButtonPressed(button:)), for: .touchUpInside)

                    let copyButton = UIButton(frame: .zero)
                    copyButton.translatesAutoresizingMaskIntoConstraints = false
                    copyButton.setImage(#imageLiteral(resourceName: "copy_icon"), for: .normal)
                    copyButton.tag = index  // capture the index of the current gamer tag for use when we copy
                    copyButton.addTarget(self, action: #selector(copyButtonPressed(button:)), for: .touchUpInside)
                    horizontalStack.addArrangedSubview(copyButton)
                }
                
            } else if user.isSignedInUser {
                let ignButton = UIButton(frame: .zero)
                ignButton.translatesAutoresizingMaskIntoConstraints = false
                ignButton.setTitle("add your gamertag", for: .normal)
                ignButton.setTitleColor(UIColor(hexString: "#CCCCCC"), for: .normal)
                ignButton.titleLabel?.font = AppConstants.Fonts.robotoRegular(13).font
                ignButton.tag = index  // capture the index of the current gamer tag for use when we copy
                horizontalStack.addArrangedSubview(ignButton)
            }
            
            if user.isSignedInUser {
                // Show edit button
                horizontalStack.addArrangedSubview(editButton)
            }
            
            gamerTagsStackView.addArrangedSubview(horizontalStack)
        }
        
        view.layoutIfNeeded()
        var size = gamerTagsStackView.bounds.size
        size.width += Constants.horizontalMargin * 2
        size.height += Constants.verticalMargin * 2
        preferredContentSize = size
        
        onDidUpdate?()
    }
    
    // MARK: Interface Actions
    
    @objc func editButtonPressed(button: UIButton) {
        guard button.tag < games.count else { return }
        
        AnalyticsManager.track(event: .profileEditGamerTagPressed)

        let game = games[button.tag]
        presentUpdateGamerTagAlert(forGame: game)
    }
    
    @objc func copyButtonPressed(button: UIButton) {
        guard let user = user, button.tag < user.gamerTags.count else { return }
        
        AnalyticsManager.track(event: .gamerTagCopied)
        
        let gamerTag = user.gamerTags[button.tag]
        UIPasteboard.general.string = gamerTag.gamerTag
        HUD.flash(.label("gamertag copied"), delay: 1)
    }

    private func presentUpdateGamerTagAlert(forGame game: Game) {
        
        let alertController = UIAlertController(title: "update \(game.title) gamertag", message: nil, preferredStyle: .alert)
        
        // Make a mutable copy
        var game = game
        
        let saveAction = UIAlertAction(title: "save", style: .default) { [weak self] _ in
            guard let ign = self?.gamerTagTextField?.text else { return }
            
            AnalyticsManager.track(event: .profileSaveGamerTagPressed)

            game.gamerTag = ign
            self?.updateSelectedGames()
        }
        self.saveAction = saveAction
        alertController.addAction(saveAction)

//        alertController.addAction(UIAlertAction(title: "remove game", style: .destructive) { _ in
//            AnalyticsManager.track(event: .profileRemoveGamerTagPressed)
//            
//            HUD.show(.progress)
//            
//            DataCoordinator.shared.getFavoriteGames({ [weak self]  (favoriteGames, error) in
//                guard let weakSelf = self else { return }
//                
//                let games = favoriteGames.filter({ $0.identifier != game.identifier })
//                
//                DataCoordinator.shared.setFavoriteGames(games: games, completion: { (error) in
//                    
//                    performOnMainThread {
//                        HUD.hide()
//                        
//                        guard error == nil else {
//                            weakSelf.presentGenericErrorAlert()
//                            return
//                        }
//                        
//                        weakSelf.getLatestProfile()
//                    }
//                })
//            })
//        })

        alertController.addTextField { textField in
            textField.addTarget(self, action: #selector(self.alertViewTextChanged(_:)), for: .editingChanged)
            textField.textAlignment = .center
            self.gamerTagTextField = textField
            textField.text = game.gamerTag
            textField.delegate = self
        }
    
        alertController.show()
    }
    
    private func updateSelectedGames() {
        guard games.count > 0 else { return }
        
        HUD.show(.progress)
        
        DataCoordinator.shared.setFavoriteGames(games: games) { [weak self] (error) in
            guard let strongself = self else { return }
            
            performOnMainThread {
                HUD.hide()
                
                guard error == nil else {
                    strongself.presentGenericErrorAlert()
                    return
                }
                
                strongself.getLatestProfile()
            }
        }
    }

}

extension GamerTagsPopUpViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == gamerTagTextField {
            // limit to 32 characters max
            let currentText = textField.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            
            guard updatedText.count <= 32 else {
                return false
            }
        }
        
        return true
    }
    
    @objc func alertViewTextChanged(_ sender: UITextField) {
        saveAction?.isEnabled = sender.text?.isEmpty == false
    }
}
