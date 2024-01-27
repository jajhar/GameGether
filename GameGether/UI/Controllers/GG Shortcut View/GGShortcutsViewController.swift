//
//  GGShortcutsViewController.swift
//  GameGether
//
//  Created by James Ajhar on 11/17/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class GGShortcutsViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var backgroundView: UIView! {
        didSet {
            // Add a gaussian blur effect to the background view
            let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.extraLight)
            let backgroundBlurEffectView = UIVisualEffectView(effect: blurEffect)
            backgroundBlurEffectView.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.addSubview(backgroundBlurEffectView)
            backgroundBlurEffectView.constrainToSuperview()
        }
    }
    
    // MARK: - Properties
    
    var onDismiss: (() -> Void)?
    var onAddGameTapped: (() -> Void)?
    var onCreateSessionTapped: (() -> Void)?
    var onCreateRequestTapped: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    // MARK: - Interface Actions
    
    @IBAction func closeButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .shortcutsCloseTapped)
        dismissSelf() { [weak self] in
            self?.onDismiss?()
        }
    }
    
    @IBAction func addGamePressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .shortcutsAddGameTapped)
        onAddGameTapped?()
    }
    
    @IBAction func createSessionPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .shortcutsCreateSessionTapped)
        onCreateSessionTapped?()
    }
    
    @IBAction func createRequestPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .shortcutsCreateRequestTapped)
        onCreateRequestTapped?()
    }
}
