//
//  GameTagsCollectionReusableView.swift
//  GameGether
//
//  Created by James Ajhar on 9/8/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import EasyTipView

class GameTagsCollectionReusableView: UICollectionReusableView {

    // MARK: Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tooltipAnchorView: UIView!
    
    // MARK: Properties
    var game: Game? {
        didSet {
            setupWithGame()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        titleLabel.font = AppConstants.Fonts.robotoLight(14).font
        titleLabel.textColor = .white
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showTooltipIfNeeded()
        }
    }
    
    private func showTooltipIfNeeded() {
        guard !DataCoordinator.shared.isUserSignedIn(),
            !UserDefaults.standard.bool(forKey: AppConstants.UserDefaults.Onboarding.gameTagsOnboardingTooltipShown) else {
                return
        }
        
        var prefs = EasyTipView.gamegetherPreferences
        prefs.drawing.arrowPosition = .bottom
        prefs.positioning.contentVInset = 10
        prefs.drawing.arrowWidth = 30
        prefs.drawing.arrowHeight = 16
        let tipView = EasyTipView.tooltip(withText: "let's explore lobbies for this game!", preferences: prefs)
        
        tipView.show(forView: tooltipAnchorView, withinSuperview: self)
        tipView.animate()
        
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { (_) in
            tipView.dismiss()
        }
    }
    
    private func setupWithGame() {
        guard let game = game else { return }
        imageView.sd_setImage(with: game.tagThemeImageURL, completed: nil)
    }
    
}
