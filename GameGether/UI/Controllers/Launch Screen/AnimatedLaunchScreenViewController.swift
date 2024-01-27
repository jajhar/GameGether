//
//  AnimatedLaunchScreenViewController.swift
//  GameGether
//
//  Created by James Ajhar on 8/22/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import FLAnimatedImage

class AnimatedLaunchScreenViewController: UIViewController {

    let animatedImageView: FLAnimatedImageView = {
        let view = FLAnimatedImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        
        if let path = Bundle.main.url(forResource: "Logo-Tilt-to-Right", withExtension: "gif"),
            let data = try? Data(contentsOf: path) {
            view.animatedImage = FLAnimatedImage(animatedGIFData: data)
        }
        
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        view.addSubview(animatedImageView)
        animatedImageView.constrainToCenterVertical()?.constant = -50
        animatedImageView.constrainToCenterHorizontal()
        animatedImageView.constrainWidth(216)
        animatedImageView.constrainHeight(174)
        view.layoutIfNeeded()
    }
}
