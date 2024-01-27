//
//  MyProfilePopUpViewController.swift
//  GameGether
//
//  Created by James Ajhar on 3/25/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class MyProfilePopUpViewController: UIViewController, ShowsNavigationOverlay {
    
    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var editProfileButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    // MARK: - Properties
    
    public var onEditProfileButtonPressed: ((UIButton) -> Void)?
    public var onUploadButtonPressed: ((UIButton) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        styleUI()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
        resize()
    }
    
    private func styleUI() {
        titleLabel.textColor = UIColor(hexString: "#4F4F4F")
        titleLabel.font = AppConstants.Fonts.robotoRegular(15).font
        
        editProfileButton.titleLabel?.font = AppConstants.Fonts.robotoRegular(14).font
        editProfileButton.setTitleColor(UIColor(hexString: "#57A2E1"), for: .normal)
        
        uploadButton.titleLabel?.font = AppConstants.Fonts.robotoRegular(14).font
        uploadButton.setTitleColor(UIColor(hexString: "#57A2E1"), for: .normal)
        
        containerView.addDropShadow(color: .black, opacity: 0.5, radius: 2)
    }
    
    private func setupView() {
        view.layoutIfNeeded()
        resize()
    }
    
    private func resize() {
        preferredContentSize = containerView.bounds.size
    }
    
    // MARK: - Interface Actions
    
    @IBAction func editProfileButtonPressed(_ sender: UIButton) {
        onEditProfileButtonPressed?(sender)
    }
    
    @IBAction func uploadGameplayButtonPressed(_ sender: UIButton) {
        onUploadButtonPressed?(sender)
    }
}
