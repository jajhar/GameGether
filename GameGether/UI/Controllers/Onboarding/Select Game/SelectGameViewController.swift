//
//  SelectGameViewController.swift
//  GameGether
//
//  Created by James Ajhar on 9/6/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD
import EasyTipView

class SelectGameViewController: UIViewController {

    // MARK: UI
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var doneButtonTooltipFrameView: UIView!
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
        }
    }
    
    @IBOutlet weak var genresCollectionView: GameGenresCollectionView! {
        didSet {
            genresCollectionView.onGenreSelected = { [weak self] (genre) in
                AnalyticsManager.track(event: .selectGameGenreSelected, withParameters: ["genre": genre.title])
                self?.genreFilteredGamesCollectionView.filter(byGenre: genre)
            }
            
            genresCollectionView.onGenreDeselected = { [weak self] (_) in
                self?.genreFilteredGamesCollectionView.filter(byGenre: nil)
            }
        }
    }
   
    @IBOutlet weak var sectionBar: SectionBarView! {
        didSet {
            sectionBar.delegate = self
            sectionBar.numberOfTabs = 2
        }
    }
    
    private var allGamesCollectionView: GamesCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let view = GamesCollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()
    
    private var genreFilteredGamesCollectionView: GamesCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let view = GamesCollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    // MARK: Properties
    private(set) var selectedGames = [Game]() {
        didSet {
            genreFilteredGamesCollectionView.selectedGames = selectedGames
            allGamesCollectionView.selectedGames = selectedGames
        }
    }
    
    var isOnboarding: Bool = false
    var onGamesSelected: (([Game]?) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        allGamesCollectionView.delegate = self
        genreFilteredGamesCollectionView.delegate = self
        
        doneButton.isEnabled = false
        
        if isOnboarding {
            backButton.isHidden = true
        }
        
        styleUI()
        getGenres()
        getFavoriteGames()
        
        scrollView.addSubview(allGamesCollectionView)
        allGamesCollectionView.constrainTo(edges: .top, .bottom, .left)
        allGamesCollectionView.constrain(attribute: .height, toItem: scrollView, attribute: .height)
        allGamesCollectionView.constrain(attribute: .width, toItem: scrollView, attribute: .width)
        
        scrollView.addSubview(genreFilteredGamesCollectionView)
        genreFilteredGamesCollectionView.constrainTo(edges: .top, .bottom, .right)
        genreFilteredGamesCollectionView.constrain(attribute: .left, toItem: allGamesCollectionView, attribute: .right)
        genreFilteredGamesCollectionView.constrain(attribute: .height, toItem: scrollView, attribute: .height)
        genreFilteredGamesCollectionView.constrain(attribute: .width, toItem: scrollView, attribute: .width)
        
        view.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showTooltipIfNeeded()
    }
    
    private func showTooltipIfNeeded() {
        guard isOnboarding else { return }
        
        // We're in the onboarding flow. Show the onboarding tooltip
        var prefs = EasyTipView.gamegetherPreferences
        prefs.drawing.arrowPosition = .bottom
        prefs.positioning.contentVInset = 10
        prefs.drawing.arrowWidth = 30
        prefs.drawing.arrowHeight = 16
        let tipView = EasyTipView.tooltip(withText: "tap above to add games you play", preferences: prefs)
        
        tipView.dismissOnTap()
        tipView.show(forView: doneButtonTooltipFrameView, withinSuperview: view)
        tipView.animate()
        
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { (_) in
            tipView.dismiss()
        }
    }
    
    private func styleUI() {
        subtitleLabel.font = AppConstants.Fonts.robotoRegular(14).font
        doneButton.titleLabel?.font = AppConstants.Fonts.robotoRegular(16).font
    }
    
    private func getGenres() {
        allGamesCollectionView.reloadDataSource { [weak self] (games, _) in
            guard let weakSelf = self else { return }
            weakSelf.genresCollectionView.genres = games.genres
        }
    }

    private func getFavoriteGames() {
        HUD.show(.progress)
        DataCoordinator.shared.getFavoriteGames { [weak self] (games, error) in
            performOnMainThread {
                HUD.hide()
                
                guard error == nil else {
                    print("Error: \(String(describing: error))")
                    return
                }
            
                self?.selectedGames = games
                self?.updateDoneButton()
            }
        }
    }
    
    private func updateDoneButton() {
        doneButton.isEnabled = selectedGames.count > 0
    }
    
    private func updateSelectedGames() {
        
        HUD.show(.progress)
        
        DataCoordinator.shared.setFavoriteGames(games: selectedGames) { [weak self] (error) in
            guard let strongself = self else { return }
            
            performOnMainThread {
                HUD.hide()
                
                guard error == nil else {
                    strongself.presentGenericErrorAlert()
                    return
                }
                
                strongself.onGamesSelected?(strongself.selectedGames)                
            }
        }
    }
    
    private func selectGame(game: Game) {
        
        if selectedGames.contains(where: { $0.identifier == game.identifier }) {
            // deselect
            selectedGames.removeGame(game)

            AnalyticsManager.track(event: .removedGame, withParameters: [
                "user": DataCoordinator.shared.signedInUser?.identifier ?? "",
                "gameId": game.identifier,
                "gameTitle": game.title
            ])

        } else {
            // select
            selectedGames.append(game)
            
            AnalyticsManager.track(event: .savedGame, withParameters: [
                "user": DataCoordinator.shared.signedInUser?.identifier ?? "",
                "gameId": game.identifier,
                "gameTitle": game.title
            ])
        }
        
        updateDoneButton()
        updateSelectedGames()
    }
    
    // MARK: Interface Actions
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        dismissSelf()
    }
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        
        AnalyticsManager.track(event: .selectGameDoneTapped)
        
        if isOnboarding {
            NavigationManager.shared.showMainView()
        } else {
            dismissSelf()
        }
    }
}

extension SelectGameViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? GameSelectionCollectionViewCell, let game = cell.game else { return }
        selectGame(game: game)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = view.bounds.width - 32 // 16*2 for insets
        let height: CGFloat = round(width * 0.3) // to scale
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 16, bottom: 125, right: 16)
    }
}

extension SelectGameViewController: SectionBarViewDelegate {
    
    func sectionBarView(view: SectionBarView, titleForTabAt index: Int) -> String {
        switch index {
        case 0:
            return "Games Supported"
        case 1:
            return "By Genre"
        default:
            return ""
        }
    }
    
    func sectionBarView(view: SectionBarView, didSelectTabAt index: Int) {
        genresCollectionView.isHidden = index != 1
        scrollTo(page: index)
        
        switch index {
        case 0:
            AnalyticsManager.track(event: .selectGameSupportedTapped)
        case 1:
            AnalyticsManager.track(event: .selectGameByGenreTapped)
        default:
            break
        }
    }
}

extension SelectGameViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }
        let page = Int(scrollView.contentOffset.x / scrollView.frame.width)
        sectionBar.selectTab(atIndex: page)
    }
    
    func scrollTo(page: Int) {
        switch page {
        case 0:
            scrollView.scrollRectToVisible(allGamesCollectionView.frame, animated: true)
        case 1:
            scrollView.scrollRectToVisible(genreFilteredGamesCollectionView.frame, animated: true)
        default:
            break
        }
    }
}
