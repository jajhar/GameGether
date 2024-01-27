//
//  GifCollectionViewCell.swift
//  GameGether
//
//  Created by James Ajhar on 1/17/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import FLAnimatedImage
import SDWebImage

class GifCollectionViewCell: UICollectionViewCell {
    
    private let gifImageView: FLAnimatedImageView = {
        let view = FLAnimatedImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.backgroundColor = .lightGray
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        gifImageView.stopAnimating()
        gifImageView.image = nil
        gifImageView.animatedImage = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        contentView.addSubview(gifImageView)
        gifImageView.constrainToSuperview()
    }
    
    func setGifImage(withGifURL url: URL) {
        gifImageView.sd_setImage(with: url, completed: nil)
    }
}
