//
//  GiphySearchCollectionView.swift
//  GameGether
//
//  Created by James Ajhar on 1/17/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import GiphyCoreSDK

class GiphySearchCollectionView: UICollectionView {
    
    enum DataSourceMode {
        case search
        case recentlyShared
    }
    
    // MARK: Properties
    var gifs: [GiphyReaction] {
        switch currentDataSource {
        case .search:
            return searchResults
        case .recentlyShared:
            return recentlySharedGifs
        }
    }
    
    private(set) var searchResults = [GiphyReaction]()
    
    lazy var recentlySharedGifs: [GiphyReaction] = {
        guard let data = UserDefaults.standard.value(forKey: AppConstants.UserDefaults.recentlySharedGIFs) as? Data,
            let gifs = try? PropertyListDecoder().decode(Array<GiphyReaction>.self, from: data) else {
            return []
        }
        
        return gifs
    }()
    
    var onGifSelected: ((GiphyReaction) -> Void)?
    var currentDataSource: DataSourceMode = .recentlyShared {
        didSet {
            reloadData()
        }
    }

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
        register(GifCollectionViewCell.self, forCellWithReuseIdentifier: GifCollectionViewCell.reuseIdentifier)
        let layout = PinterestLayout()
        collectionViewLayout = layout
        layout.delegate = self
        layout.cellPadding = 1
        layout.numberOfColumns = 2
    }
    
    func search(forGifsWithQuery query: String) {
        
        currentDataSource = .search

        let spinner = displaySpinner()

        // Gif Search
        GiphyCore.shared.search(query, limit: 100, rating: .ratedPG13) { [weak self] (response, error) in
            performOnMainThread {
                
                performOnMainThread {
                    self?.removeSpinner(spinner: spinner)
                }
                
                if let error = error {
                    GGLog.error("\(error.localizedDescription)")
                    return
                }
                
                if let response = response, let data = response.data {
                    self?.searchResults.removeAll()
                    for item in data {
                        guard let giphyGif =  item.images?.fixedWidth,
                            let contentURL = giphyGif.gifUrl,
                            let url = URL(string: contentURL) else { continue }
                        
                        let gif = GiphyReaction(title: "", url: url, size: CGSize(width: giphyGif.width, height: giphyGif.height))
                        self?.searchResults.append(gif)
                    }
                } else {
                    // Nothing found for this query
                    self?.searchResults.removeAll()
                    self?.currentDataSource = .recentlyShared
                }
                
                performOnMainThread {
                    self?.reloadData()
                }
            }
        }
    }
    
    private func saveRecentlySharedGif(_ gif: GiphyReaction) {
        recentlySharedGifs.insert(gif, at: 0)
        let defaults = UserDefaults.standard
        defaults.setValue(try? PropertyListEncoder().encode(recentlySharedGifs), forKey: AppConstants.UserDefaults.recentlySharedGIFs)
        defaults.synchronize()
    }
}

extension GiphySearchCollectionView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GifCollectionViewCell.reuseIdentifier, for: indexPath) as! GifCollectionViewCell
        
        let gif = gifs[indexPath.item]
        cell.setGifImage(withGifURL: gif.url)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let gif = gifs[indexPath.item]
        saveRecentlySharedGif(gif)
        onGifSelected?(gif)
    }
}

extension GiphySearchCollectionView: PinterestLayoutDelegate {
    
    func collectionView(collectionView: UICollectionView, heightForImageAtIndexPath indexPath: IndexPath, withWidth: CGFloat) -> CGFloat {
        let gif = gifs[indexPath.item]
        return CGFloat(gif.size?.height ?? 200)
    }
    
    func collectionView(collectionView: UICollectionView, heightForAnnotationAtIndexPath indexPath: IndexPath, withWidth: CGFloat) -> CGFloat {
        return 0
    }
}
