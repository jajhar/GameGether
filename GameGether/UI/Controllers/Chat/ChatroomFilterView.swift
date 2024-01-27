//
//  ChatroomFilterView.swift
//  GameGether
//
//  Created by James Ajhar on 2/14/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class ChatroomFilterView: UIView {

    // MARK: Properties
    private let firebaseChat = FirebaseChat()

    private let stackView: UIStackView = {
        let stack = UIStackView(frame: .zero)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    private let scrollView: UIScrollView = {
        let view = UIScrollView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    var onHomeSelected: (() -> Void)?
    var onGameSelected: ((Game) -> Void)?

    private(set) var favoriteGames = [Game]()
    private var buttonViews = [ChatroomFilterButton]()
    
    var user: User? {
        didSet {
            reload()
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
        addSubview(scrollView)
        scrollView.constrainToSuperview()
        
        let container = UIView(frame: .zero)
        container.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(container)
        container.constrainToSuperview()
        container.constrainToCenterHorizontal()
        container.constrain(attribute: .width, toItem: scrollView, attribute: .width)
        
        container.addSubview(stackView)
        stackView.constrainTo(edge: .right)                 // right side has no drop shadow
        stackView.constrainTo(edge: .left)?.constant = 2    // leave 2 point space for the drop shadow
        stackView.constrainTo(edge: .top)?.constant = 2     // leave 2 point space for the drop shadow
        stackView.constrainTo(edge: .bottom)?.constant = -2  // leave 2 point space for the drop shadow
        layoutIfNeeded()
    }
    
    public func reload() {
        getFavoriteGames()
    }
    
    private func getFavoriteGames() {
        DataCoordinator.shared.getFavoriteGames { [weak self] (games, error) in
            performOnMainThread {
                
                guard error == nil else {
                    print("Error: \(String(describing: error))")
                    return
                }
                
                self?.favoriteGames = games
                self?.setupStackView(withGames: games)
                self?.observeUnreadMessageCount()
            }
        }
    }
    
    @objc func homeButtonTapped(button: UIButton) {
        selectButton(withTag: button.tag)
        onHomeSelected?()
    }

    @objc func gameButtonTapped(button: UIButton) {
        guard button.tag < favoriteGames.count else { return }
        let game = favoriteGames[button.tag]
        selectButton(withTag: button.tag)
        onGameSelected?(game)
    }
    
    private func selectButton(withTag tag: Int) {
        for view in buttonViews {
            view.setSelected(view.tag == tag)
        }
    }

    private func setupStackView(withGames games: [Game]) {
        _ = stackView.arrangedSubviews.compactMap({ $0.removeFromSuperview() })
        buttonViews.removeAll()
        
        // Add the home button
        let container = ChatroomFilterButton(frame: .zero)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.tag = -1
        container.imageView.image = #imageLiteral(resourceName: "ChatHome - Right Nav")
        container.button.addTarget(self, action: #selector(homeButtonTapped(button:)), for: .touchUpInside)
        stackView.addArrangedSubview(container)
        container.constrainHeight(stackView.bounds.width)
        buttonViews.append(container)
        container.setSelected(true)

        // Add the user's favorite games list
        for (index, game) in games.enumerated() {
            let container = ChatroomFilterButton(frame: .zero)
            container.game = game
            container.translatesAutoresizingMaskIntoConstraints = false
            container.tag = index
            container.imageView.sd_setImage(with: game.iconImageURL, completed: nil)
            container.button.addTarget(self, action: #selector(gameButtonTapped(button:)), for: .touchUpInside)
            stackView.addArrangedSubview(container)
            container.constrainHeight(stackView.bounds.width)
            buttonViews.append(container)
        }
        
        layoutIfNeeded()
    }
    
    private func observeUnreadMessageCount() {
        firebaseChat.signIn { [weak self] (result, error) in
            self?.firebaseChat.observeTotalChatroomUnreadMessageCount(completion: { (unreadChatroomsTuples, totalUnreadCount) in
                guard let weakSelf = self else { return }
                
                var games = [Game]()
                for tuple in unreadChatroomsTuples {
                    guard let game = tuple.0.game else { continue }
                    games.append(game)
                }
                
                performOnMainThread {
                    // Home button must always show a notification if totalUnreadCount > 0 since it contains ALL chatrooms so it MUST have a notification.
                    weakSelf.buttonViews.first?.showNotification(totalUnreadCount > 0)
                    weakSelf.showNotifications(forGames: games)
                }
            })
        }
    }
    
    func showNotifications(forGames games: [Game]) {
        for view in buttonViews {
            guard let game = view.game else { continue }
            view.showNotification(games.filter({ $0.identifier == game.identifier}).first != nil)
        }
    }
}

private class ChatroomFilterButton: UIView {
    
    var game: Game?
    
    let imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.cornerRadius = 9
        return imageView
    }()
    
    let button: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let roundedBackgroundView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.layer.cornerRadius = 10
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        view.backgroundColor = .clear
        return view
    }()
    
    let notificationDot: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = #imageLiteral(resourceName: "Oval 3")
        return imageView
    }()
    
    override var tag: Int {
        didSet {
            button.tag = tag
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(roundedBackgroundView)
        roundedBackgroundView.constrainToSuperview()

        addSubview(imageView)
        imageView.constrainToCenter()
        imageView.constrainWidth(30)
        imageView.constrainHeight(30)
        
        addSubview(notificationDot)
        notificationDot.constrain(attribute: .trailing, toItem: imageView, attribute: .trailing)?.constant = 5
        notificationDot.constrain(attribute: .top, toItem: imageView, attribute: .top)?.constant = -5
        notificationDot.isHidden = true // Hidden by default
        
        addSubview(button)
        button.constrainToSuperview()
        
        addDropShadow(color: .black, opacity: 0.22, radius: 2)
        
        setSelected(false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSelected(_ isSelected: Bool) {
        if isSelected {
            roundedBackgroundView.backgroundColor = UIColor(hexString: "#F4F4F4")
            imageView.alpha = 1.0
        } else {
            roundedBackgroundView.backgroundColor = .clear
            imageView.alpha = 0.3
        }
    }
    
    func showNotification(_ show: Bool) {
        notificationDot.isHidden = !show
    }
}
