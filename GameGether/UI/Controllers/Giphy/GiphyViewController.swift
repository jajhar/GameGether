//
//  GiphyViewController.swift
//  GameGether
//
//  Created by James Ajhar on 1/17/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import GiphyCoreSDK
import SDWebImage

struct GiphyReaction: Codable {
    var title: String = ""
    var url: URL
    var size: CGSize?
}

class GiphyViewController: UIViewController {

    enum GiphyMode {
        case reactions
        case trending
    }
    
    // MARK: Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var poweredByGiphyImage: UIImageView!
    @IBOutlet weak var reactionsButton: UIButton!
    @IBOutlet weak var trendingButton: UIButton!
    
    // MARK: Properties
    private var currentMode: GiphyMode = .reactions

    private let reactionGifs = [
        GiphyReaction(title: "LOL", url: URL(string: "https://media.giphy.com/media/ZqlvCTNHpqrio/giphy.gif")!, size: nil),
        GiphyReaction(title: "Shimmy", url: URL(string: "https://media.giphy.com/media/W80Y9y1XwiL84/giphy.gif")!, size: nil),
        GiphyReaction(title: "Excited", url: URL(string: "https://media.giphy.com/media/5GoVLqeAOo6PK/giphy.gif")!, size: nil),
        GiphyReaction(title: "Sad", url: URL(string: "https://media.giphy.com/media/9Y5BbDSkSTiY8/giphy.gif")!, size: nil),
        GiphyReaction(title: "Confused", url: URL(string: "https://media.giphy.com/media/kaq6GnxDlJaBq/giphy.gif")!, size: nil),
        GiphyReaction(title: "Mind blown", url: URL(string: "https://media.giphy.com/media/xT0xeJpnrWC4XWblEk/giphy.gif")!, size: nil),
        GiphyReaction(title: "Wink", url: URL(string: "https://media.giphy.com/media/l4FB6rJP7S6wxJvKU/giphy.gif")!, size: nil),
        GiphyReaction(title: "Thumbs Up", url: URL(string: "https://media.giphy.com/media/111ebonMs90YLu/giphy.gif")!, size: nil),
        GiphyReaction(title: "Eye roll", url: URL(string: "https://media.giphy.com/media/dEdmW17JnZhiU/giphy.gif")!, size: nil),
        GiphyReaction(title: "Face palm", url: URL(string: "https://media.giphy.com/media/tZiLOffTNGoak/giphy.gif")!, size: nil),
        GiphyReaction(title: "Deal with it", url: URL(string: "https://media.giphy.com/media/3ztiZa4eICWGs/giphy.gif")!, size: nil),
        GiphyReaction(title: "Thank you", url: URL(string: "https://media.giphy.com/media/6tHy8UAbv3zgs/giphy.gif")!, size: nil)
    ]
    
    private var trendingGifs = [GiphyReaction]()
    
    private var gifs: [GiphyReaction] {
        switch currentMode {
        case .reactions:
            return reactionGifs
        case .trending:
            return trendingGifs
        }
    }
    
    var onGifSelected: ((GiphyReaction) -> Void)?
    var onBackButtonPressed: (() -> Void)?
    var didShowGiphyLogo: Bool = false

    deinit {
        SDImageCache.shared().clearMemory()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleUI()

        collectionView.register(GiphyReactionCollectionViewCell.self, forCellWithReuseIdentifier: GiphyReactionCollectionViewCell.reuseIdentifier)
        let layout = PinterestLayout()
        collectionView.collectionViewLayout = layout
        layout.delegate = self
        layout.cellPadding = 1
        layout.numberOfColumns = 2

        setMode(mode: .reactions)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !didShowGiphyLogo {
            didShowGiphyLogo = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                UIView.animate(withDuration: 1.0, animations: {
                    self?.poweredByGiphyImage.alpha = 0.0
                }, completion: { _ in
                    self?.poweredByGiphyImage.removeFromSuperview()
                })
            }
        }
    }
    
    private func styleUI() {
        reactionsButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(14).font
        trendingButton.titleLabel?.font = AppConstants.Fonts.robotoMedium(14).font
        
        reactionsButton.setBackgroundColor(color: UIColor(hexString: "#E0E0E0"), forState: .normal)
        reactionsButton.setBackgroundColor(color: UIColor(hexString: "#57A2E1"), forState: .selected)
        trendingButton.setBackgroundColor(color: UIColor(hexString: "#E0E0E0"), forState: .normal)
        trendingButton.setBackgroundColor(color: UIColor(hexString: "#57A2E1"), forState: .selected)
    }
    
    private func setMode(mode: GiphyMode) {
        currentMode = mode
        reactionsButton.isSelected = mode == .reactions
        trendingButton.isSelected = mode == .trending
        collectionView.reloadData()
        getTrendingGIFs()
    }
    
    private func getTrendingGIFs() {
        let spinner = collectionView.displaySpinner()
        
        // Trending GIFs
        GiphyCore.shared.trending(limit: 100, rating: .ratedPG13) { [weak self] (response, error) in
            performOnMainThread {
                
                self?.view.removeSpinner(spinner: spinner)

                if let error = error {
                    GGLog.error("\(error.localizedDescription)")
                    return
                }
                
                if let response = response, let data = response.data {
                    self?.trendingGifs.removeAll()
                    for item in data {
                        guard let giphyGif =  item.images?.fixedWidthDownsampled,
                            let contentURL = giphyGif.gifUrl,
                            let url = URL(string: contentURL) else { continue }

                        let gif = GiphyReaction(title: "", url: url, size: CGSize(width: giphyGif.width, height: giphyGif.height))
                        self?.trendingGifs.append(gif)
                    }
                }
            }
        }
    }
    
    private func showSearchVC(withQuery query: String? = nil) {
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.giphy, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: GiphySearchViewController.storyboardIdentifier) as! GiphySearchViewController

        vc.onGifSelected = { [weak self, weak vc] (gif) in
            vc?.dismissSelf()
            self?.onGifSelected?(gif)
        }
        
        vc.query = query
        NavigationManager.shared.present(vc)
    }
    
    // MARK: Interface Actions
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .giphyCloseButtonTapped)
        onBackButtonPressed?()
    }
    
    @IBAction func reactionsButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .giphyReactionsButtonTapped)
        setMode(mode: .reactions)
    }
    
    @IBAction func trendingButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .giphyTrendingButtonTapped)
        setMode(mode: .trending)
    }
    
    @IBAction func searchButtonPressed(_ sender: UIButton) {
        AnalyticsManager.track(event: .giphySearchButtonTapped)
        showSearchVC()
    }
}

extension GiphyViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GiphyReactionCollectionViewCell.reuseIdentifier, for: indexPath) as! GiphyReactionCollectionViewCell
        let gif = gifs[indexPath.item]
        cell.titleLabel.text = gif.title
        cell.imageView.sd_setImage(with: gif.url, completed: nil)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch currentMode {
        case .reactions:
            showSearchVC(withQuery: gifs[indexPath.item].title)
        case .trending:
            onGifSelected?(gifs[indexPath.item])
        }
    }
}

extension GiphyViewController: PinterestLayoutDelegate {
    
    func collectionView(collectionView: UICollectionView, heightForImageAtIndexPath indexPath: IndexPath, withWidth: CGFloat) -> CGFloat {
        let gif = gifs[indexPath.item]
        // Default height of cell is the view's height divided by the number of gifs in a single colum (given there are 2 columns)
        // -15 for cell spacing
        let defaultHeight: CGFloat = 122.0
        return CGFloat(gif.size?.height ?? defaultHeight)
    }
    
    func collectionView(collectionView: UICollectionView, heightForAnnotationAtIndexPath indexPath: IndexPath, withWidth: CGFloat) -> CGFloat {
        return 0
    }
}
