//
//  PlayLaterSessionsViewController.swift
//  GameGether
//
//  Created by James Ajhar on 9/16/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import FLAnimatedImage

class PlayLaterSessionsViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var collectionView: GameSessionsCollectionView! {
        didSet {
            
            collectionView.filter = .allSessions
            collectionView.contentInset = UIEdgeInsets(top: 35, left: 0, bottom: 150, right: 0)
            
            collectionView.onSessionSelected = { [weak self] (session) in
                self?.onSessionSelected?(session)
            }
            
            collectionView.onCreateSessionCellTapped = { [weak self] (_) in
                self?.onCreateSessionCellTapped?()
            }
            
            collectionView.onActiveLobbySelected = { (activeLobby) in
                
                AnalyticsManager.track(event: .playNowSessionSelected, withParameters: ["game": activeLobby.game?.title ?? "",
                                                                                        "gameId": activeLobby.game?.identifier ?? "",
                                                                                        "tags": activeLobby.tags.compactMap({ $0.title }),
                                                                                        "tagIds": activeLobby.tags.compactMap({ $0.identifier })])
                
                // Present the lobby
                let lobbyVC = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: GameLobbyContainerViewController.storyboardIdentifier) as! GameLobbyContainerViewController
                lobbyVC.loadViewIfNeeded()
                lobbyVC.shouldRestoreBookmarkedTags = false
                lobbyVC.game = activeLobby.game
                lobbyVC.tagsChatViewController?.selectedTags = activeLobby.tags

                let nav = GGNavigationViewController(rootViewController: lobbyVC)
                nav.hidesBottomBarWhenPushed = true
                nav.isNavigationBarHidden = true
                nav.modalTransitionStyle = .crossDissolve

                NavigationManager.shared.present(nav)
            }

//            collectionView.onSectionChanged = { [weak self] (title, _) in
//                guard let weakSelf = self else { return }
//                weakSelf.dateHeaderLabel.text = title
//            }
        }
    }
    
    @IBOutlet weak var dateHeaderLabel: UILabel! {
        didSet {
            dateHeaderLabel.font = AppConstants.Fonts.robotoMedium(17).font
            dateHeaderLabel.text = "Play With"
        }
    }
    
    @IBOutlet weak var sessionsFilterButton: UIButton! {
        didSet {
            sessionsFilterButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(14).font
        }
    }
    
    // MARK: - Properties
    var game: Game?
    var tags: [Tag]?
    
    let loadingImageView: FLAnimatedImageView = {
        let view = FLAnimatedImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .white
        
        if let path = Bundle.main.url(forResource: "GGHome-Loading", withExtension: "gif"),
            let data = try? Data(contentsOf: path) {
            view.animatedImage = FLAnimatedImage(animatedGIFData: data)
        }
        
        return view
    }()

    var onSessionSelected: ((GameSession) -> Void)?
    var onCreateSessionCellTapped: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(loadingImageView)
        loadingImageView.constrainToSuperview()
        view.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadDataSource()
    }
    
    func reloadDataSource() {
        loadingImageView.isHidden = false
        collectionView.reloadDataSource(withGame: game, andTags: tags) { [weak self] in
            self?.loadingImageView.isHidden = true
        }
    }
    
    public func reload() {
        collectionView.reloadData()
    }
    
    private func toggleCollectionFilter() {
        switch collectionView.filter {
        case .allSessions, .allSessionsAndPlayNow:
            collectionView.filter = .mySessions
            sessionsFilterButton.setTitle("show all groups", for: .normal)
            
        case .mySessions:
            collectionView.filter = .allSessions
            sessionsFilterButton.setTitle("show joined groups", for: .normal)
        }
        
        collectionView.scrollToTop()
        reloadDataSource()
    }
    
    // MARK: - Interface Actions
    
    @IBAction func sessionsFilterButtonPressed(_ sender: Any) {
        guard DataCoordinator.shared.isUserSignedIn() else {
            // onboarding, go to create account screen
            let viewController = UIStoryboard(name: AppConstants.Storyboards.onboarding, bundle: nil).instantiateViewController(withIdentifier: RegisterUserViewController.storyboardIdentifier)
            let nav = GGNavigationViewController(rootViewController: viewController)
            NavigationManager.shared.present(nav)

            return
        }
        
        toggleCollectionFilter()
    }
    
}
