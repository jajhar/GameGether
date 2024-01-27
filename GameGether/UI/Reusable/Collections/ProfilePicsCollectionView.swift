//
//  ProfilePicsCollectionView.swift
//  GameGether
//
//  Created by James Ajhar on 8/12/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

protocol ProfilePicsCollectionViewDelegate {
    func profilePicCollectionView(_ collectionView: ProfilePicsCollectionView, didSelectProfilePic imageURL: URL)
}

class ProfilePicsCollectionView: UICollectionView {

    public struct Constants {
        static let profilePics: [URL] = [
            URL(string: "https://d29y84nmsvv3wc.cloudfront.net/Pastel-Green-66CC33.png")!,
            URL(string: "https://d29y84nmsvv3wc.cloudfront.net/Pastel-Orange-66CC33.png")!,
            URL(string: "https://d29y84nmsvv3wc.cloudfront.net/Pastel-Pink-66CC33.png")!,
            URL(string: "https://d29y84nmsvv3wc.cloudfront.net/Gradient-PastelOrange-Mustard.png")!,
            URL(string: "https://d29y84nmsvv3wc.cloudfront.net/Gradient-Pastel-Blue-Mustard.png")!,
            URL(string: "https://d29y84nmsvv3wc.cloudfront.net/Gradient-Dark-Tint.png")!
        ]
    }
    
    public var profilePicCollectionDelegate: ProfilePicsCollectionViewDelegate?
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    internal func commonInit() {
        dataSource = self
        delegate = self
        (collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = CGSize(width: 40, height: 40)
        register(ProfilePicCollectionViewCell.self, forCellWithReuseIdentifier: ProfilePicCollectionViewCell.reuseIdentifier)
    }
}

extension ProfilePicsCollectionView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
 
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Constants.profilePics.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePicCollectionViewCell.reuseIdentifier, for: indexPath) as! ProfilePicCollectionViewCell
        cell.imageView.sd_setImage(with:  Constants.profilePics[indexPath.item], completed: nil)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        // Make sure that the number of items is worth the computing effort.
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout,
            let dataSourceCount = collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: section),
            dataSourceCount > 0 else {
                return .zero
        }
        
        let cellCount = CGFloat(dataSourceCount)
        let itemSpacing = flowLayout.minimumInteritemSpacing
        let cellWidth = flowLayout.itemSize.width + itemSpacing
        var insets = flowLayout.sectionInset
        
        // Make sure to remove the last item spacing or it will
        // miscalculate the actual total width.
        let totalCellWidth = (cellWidth * cellCount) - itemSpacing
        let contentWidth = collectionView.frame.size.width - collectionView.contentInset.left - collectionView.contentInset.right
        
        // If the number of cells that exist take up less room than the
        // collection view width, then center the content with the appropriate insets.
        // Otherwise return the default layout inset.
        guard totalCellWidth < contentWidth else {
            return insets
        }
        
        // Calculate the right amount of padding to center the cells.
        let padding = (contentWidth - totalCellWidth) / 2.0
        insets.left = padding
        insets.right = padding
        return insets
    }

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 40, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        profilePicCollectionDelegate?.profilePicCollectionView(self, didSelectProfilePic: Constants.profilePics[indexPath.item])
    }
}

class ProfilePicCollectionViewCell: UICollectionViewCell {
    
    let imageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = AppConstants.Fonts.robotoRegular(18).font
        label.textColor = .white
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        imageView.sd_cancelCurrentImageLoad()
    }
    
    private func commonInit() {
        contentView.addSubview(imageView)
        imageView.constrainToSuperview()
        
        contentView.addSubview(titleLabel)
        titleLabel.constrainToSuperview()
        
        contentView.layoutIfNeeded()
    }
    
    public func setTitle(_ title: String) {
        titleLabel.text = title
    }
}
