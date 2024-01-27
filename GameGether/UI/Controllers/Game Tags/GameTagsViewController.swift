//
//  GameTagsViewController.swift
//  GameGether
//
//  Created by James Ajhar on 9/8/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import SDWebImage

class GameTagsViewController: UIViewController {

    struct Constants {
        static let rightNavHomeIndex = 0
        static let rightNavChatIndex = 1
        static let rightNavUsersIndex = 2
    }
    
    // MARK: Outlets
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerTopMarginView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var gameTagsCollectionView: LobbiesCollectionView!
    
    // MARK: Properties
    
    var game: Game?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var joystickImage: NavigationJoystickViewImage {
        return .doItMyDamnSelf
    }
    
    private let firebaseParty = FirebaseParty()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleUI()
        
        firebaseParty.signIn()
        
        gameTagsCollectionView.onTagsSelected = { [weak self] (tags) in
            let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: GameLobbyContainerViewController.storyboardIdentifier) as! GameLobbyContainerViewController
            viewController.loadViewIfNeeded()
            viewController.shouldRestoreBookmarkedTags = false
            viewController.game = self?.game
            viewController.tagsChatViewController?.selectedTags = tags
            
            if tags.count == 0 {
                // go to general lobby
                AnalyticsManager.track(event: .gameTagsGeneralLobbyPressed)
            }
            
            self?.navigationController?.pushViewController(viewController, animated: true)
        }
        
        gameTagsCollectionView.onEmptyStateCellSelected = { [weak self] in
            let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: GameLobbyContainerViewController.storyboardIdentifier) as! GameLobbyContainerViewController
            viewController.loadViewIfNeeded()
            viewController.shouldRestoreBookmarkedTags = false
            viewController.game = self?.game
            viewController.tagsChatViewController?.showWalkthroughOnAppear = true   // show the lobby walkthrough
            
            AnalyticsManager.track(event: .gameTagsEmptyStatePressed)

            self?.navigationController?.pushViewController(viewController, animated: true)
        }
        
        gameTagsCollectionView.game = game
        setupWithGame()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setNeedsStatusBarAppearanceUpdate()

        gameTagsCollectionView.reloadDataSource()
        
        SDWebImageManager.shared().imageDownloader?.downloadImage(with: game?.iconImageURL, options: [], progress: nil) { (image, _, _, _) in
            performOnMainThread {
                if let image = image {
                    NavigationManager.shared.navigationOverlay?.joystickImage = .custom(image)
                }
            }
        }
        
        NavigationManager.shared.navigationOverlay?.onAIButtonTapped = { [weak self] (_) in
            guard let weakSelf = self, weakSelf.isVisible else { return }
            
            if !DataCoordinator.shared.isUserSignedIn() {
                // onboarding, go to create account screen
                let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
                let nav = GGNavigationViewController(rootViewController: viewController)
                NavigationManager.shared.present(nav)
            }
        }
        
        fetchGame()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NavigationManager.shared.navigationOverlay?.onAIButtonTapped = nil
    }

    private func styleUI() {
        titleLabel.font = AppConstants.Fonts.robotoBold(21).font
        titleLabel.textColor = .white
        headerView.backgroundColor = UIColor(hexString: game?.headerColor ?? "#57A2E1")
        headerTopMarginView.backgroundColor = UIColor(hexString: game?.headerColor ?? "#57A2E1")
    }
    
    private func setupWithGame() {
        guard let game = game else { return }
        
        titleLabel.text = game.title
    }
    
    private func fetchGame() {
        guard let game = game else { return }
        
        DataCoordinator.shared.getGames { [weak self] (games, error) in
            performOnMainThread {
                guard let updatedGame = games.filter({ $0.identifier == game.identifier }).first else { return }
                self?.game = updatedGame
                self?.setupWithGame()
            }
        }
    }
}
