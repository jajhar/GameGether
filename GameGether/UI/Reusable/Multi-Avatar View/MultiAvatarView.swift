//
//  MultiAvatarView.swift
//  GameGether
//
//  Created by James Ajhar on 8/9/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class MultiAvatarView: UIView {
    
    // MARK: Properties
    private(set) var imageView1: AvatarInitialsImageView?
    private(set) var imageView2: AvatarInitialsImageView?
    private(set) var imageView3: AvatarInitialsImageView?
    private(set) var imageView4: AvatarInitialsImageView?

    var users = [User]() {
        didSet {
            layoutImages()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        // NOP
    }
    
    func prepareForReuse() {
        imageView1?.removeFromSuperview()
        imageView2?.removeFromSuperview()
        imageView3?.removeFromSuperview()
        imageView4?.removeFromSuperview()
    }
    
    private func imageView(size: CGFloat) -> AvatarInitialsImageView {
        let view = AvatarInitialsImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        view.backgroundColor = .lightGray
        view.constrainWidth(size)
        view.constrainHeight(size)
        view.image = #imageLiteral(resourceName: "Pastel Green #66CC33")
        view.layer.cornerRadius = size / 2
        return view
    }
    
    private func layoutImages() {
        prepareForReuse()
        
        if users.count <= 1 {
            showSingleAvatarView()
        } else if users.count == 2 {
            showTwoAvatarLayout()
        } else if users.count == 3 {
            showThreeAvatarLayout()
        } else if users.count == 4 {
            showFourAvatarLayout()
        } else {
            showMaxAvatarLayout()
        }
    }
    
    private func showSingleAvatarView() {
        let view1 = imageView(size: self.bounds.width)
        view1.image = #imageLiteral(resourceName: "Pastel Green #66CC33")
        addSubview(view1)
        view1.constrainToSuperview()
        
        imageView1 = view1
        
        if let user = users.first {
            imageView1?.configure(withUser: user, andFont: AppConstants.Fonts.robotoRegular(16).font)
        }
    }
    
    private func showTwoAvatarLayout() {
        let view1 = imageView(size: 28)
        let view2 = imageView(size: 28)
       
        view1.image = #imageLiteral(resourceName: "Pastel Green #66CC33")
        view2.image = #imageLiteral(resourceName: "Pastel Green #66CC33")

        addSubview(view1)
        addSubview(view2)
        
        view1.constrainTo(edges: .left, .top)
        view2.constrainTo(edges: .right, .bottom)
        
        imageView1 = view1
        imageView2 = view2

        for i in 0..<users.count {
            if i == 0 {
                imageView1?.configure(withUser: users[i], andFont: AppConstants.Fonts.robotoRegular(16).font)
            } else {
                imageView2?.configure(withUser: users[i], andFont: AppConstants.Fonts.robotoRegular(16).font)
            }
        }
    }
    
    private func showThreeAvatarLayout() {
        let view1 = imageView(size: 25)
        let view2 = imageView(size: 25)
        let view3 = imageView(size: 25)

        view1.image = #imageLiteral(resourceName: "Pastel Green #66CC33")
        view2.image = #imageLiteral(resourceName: "Pastel Green #66CC33")
        view3.image = #imageLiteral(resourceName: "Pastel Green #66CC33")

        addSubview(view1)
        addSubview(view2)
        addSubview(view3)

        view1.constrainTo(edge: .top)
        view1.constrainToCenterHorizontal()
        view2.constrainTo(edges: .left, .bottom)
        view3.constrainTo(edges: .right, .bottom)

        imageView1 = view1
        imageView2 = view2
        imageView3 = view3
        
        for i in 0..<users.count {
            if i == 0 {
                imageView1?.configure(withUser: users[i], andFont: AppConstants.Fonts.robotoRegular(16).font)
            } else if i == 1 {
                imageView2?.configure(withUser: users[i], andFont: AppConstants.Fonts.robotoRegular(16).font)
            } else {
                imageView3?.configure(withUser: users[i], andFont: AppConstants.Fonts.robotoRegular(16).font)
            }
        }
    }
    
    private func showFourAvatarLayout() {
        let view1 = imageView(size: 24)
        let view2 = imageView(size: 24)
        let view3 = imageView(size: 24)
        let view4 = imageView(size: 24)

        view1.image = #imageLiteral(resourceName: "Pastel Green #66CC33")
        view2.image = #imageLiteral(resourceName: "Pastel Green #66CC33")
        view3.image = #imageLiteral(resourceName: "Pastel Green #66CC33")
        view4.image = #imageLiteral(resourceName: "Pastel Green #66CC33")

        addSubview(view1)
        addSubview(view2)
        addSubview(view3)
        addSubview(view4)

        view1.constrainTo(edges: .top, .left)
        view2.constrainTo(edges: .top, .right)
        view3.constrainTo(edges: .bottom, .right)
        view4.constrainTo(edges: .bottom, .left)

        imageView1 = view1
        imageView2 = view2
        imageView3 = view3
        imageView4 = view4

        for i in 0..<users.count {
            if i == 0 {
                imageView1?.configure(withUser: users[i], andFont: AppConstants.Fonts.robotoRegular(16).font)
            } else if i == 1 {
                imageView2?.configure(withUser: users[i], andFont: AppConstants.Fonts.robotoRegular(16).font)
            } else if i == 2 {
                imageView3?.configure(withUser: users[i], andFont: AppConstants.Fonts.robotoRegular(16).font)
            } else {
                imageView4?.configure(withUser: users[i], andFont: AppConstants.Fonts.robotoRegular(16).font)
            }
        }
    }
    
    private func showMaxAvatarLayout() {
        let view1 = imageView(size: 30)
        let view2 = imageView(size: 30)
        let view3 = imageView(size: 30)
        let view4 = imageView(size: 30)
        
        view1.image = #imageLiteral(resourceName: "Pastel Green #66CC33")
        view2.image = #imageLiteral(resourceName: "Pastel Green #66CC33")
        view3.image = #imageLiteral(resourceName: "Pastel Green #66CC33")
        view4.image = #imageLiteral(resourceName: "Pastel Green #66CC33")

        addSubview(view4)
        addSubview(view3)
        addSubview(view2)
        addSubview(view1)
        
        view1.constrainTo(edge: .left)
        view1.constrainToCenterVertical()
        view2.constrainTo(edge: .left)?.constant = (bounds.width / 8)
        view2.constrainToCenterVertical()
        view3.constrainTo(edge: .left)?.constant = 2*(bounds.width / 8)
        view3.constrainToCenterVertical()
        view4.constrainTo(edge: .left)?.constant = 3*(bounds.width / 8)
        view4.constrainToCenterVertical()
        
        imageView1 = view1
        imageView2 = view2
        imageView3 = view3
        imageView4 = view4
        
        for i in 0..<users.count {
            if i == 0 {
                imageView1?.configure(withUser: users[i], andFont: AppConstants.Fonts.robotoRegular(16).font)
            } else if i == 1 {
                imageView2?.configure(withUser: users[i], andFont: AppConstants.Fonts.robotoRegular(16).font)
            } else if i == 2 {
                imageView3?.configure(withUser: users[i], andFont: AppConstants.Fonts.robotoRegular(16).font)
            } else {
                imageView4?.configure(withUser: users[i], andFont: AppConstants.Fonts.robotoRegular(16).font)
            }
        }
    }
}
