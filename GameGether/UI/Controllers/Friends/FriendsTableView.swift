//
//  FriendsTableView.swift
//  GameGether
//
//  Created by James Ajhar on 8/6/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit
import ViewAnimator

protocol FriendsTableViewDelegate: class {
    func tableView(_ tableView: FriendsTableView, willRenderCell cell: UserTableViewCell, AtIndexPath indexPath: IndexPath)
}

class FriendsTableView: UITableView {

    private(set) var friends: [User] = [User]()
    private(set) var filteredDatasource: [User] = [User]()
    
    var ignoredUserIds: [String] = [String]()
    
    weak var friendsTableViewDelegate: FriendsTableViewDelegate?
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        dataSource = self
        delegate = self
        separatorStyle = .none
        allowsSelection = true
        register(UINib(nibName: "\(UserTableViewCell.self)", bundle: nil),
                 forCellReuseIdentifier: UserTableViewCell.reuseIdentifier)
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = 44
        contentInset = UIEdgeInsets.init(top: 10, left: 0, bottom: 100, right: 0)
        reloadDataSource()
    }
    
    func filter(byUsername username: String) {
        filteredDatasource = friends.filter({
            $0.ign.lowercased().range(of: username.lowercased()) != nil
        }).sorted(by: {
            ($0.status.order, $0.ign) < ($1.status.order, $1.ign)
        })
        reloadData()
    }
    
    func resetFilter() {
        filteredDatasource = friends
        reloadData()
    }
    
    func reloadDataSource(_ completion: (([User], Error?) -> Void)? = nil) {
        
        let spinner = displaySpinner()

        DataCoordinator.shared.getFriends(ignoreCache: true) { [weak self] (users, error) in
            performOnMainThread {
                
                defer {
                    completion?(users ?? [], error)
                }
                
                self?.removeSpinner(spinner: spinner)

                guard let strongself = self, error == nil, let users = users else {
                    GGLog.error("\(String(describing: error))")
                    return
                }
                
                var nonIgnoredUsers = [User]()
                
                for user in users {
                    if strongself.ignoredUserIds.filter({ $0 == user.identifier }).first == nil {
                        nonIgnoredUsers.append(user)
                    }
                }
                
                strongself.friends = nonIgnoredUsers.sorted(by: {
                    let date1: Date = $0.lastOnline ?? Date().subtractYears(1)!
                    let date2: Date = $1.lastOnline ?? Date().subtractYears(1)!
                    return date1 > date2
                })
                
                let shouldAnimate: Bool = strongself.filteredDatasource.count != strongself.friends.count
                strongself.filteredDatasource = strongself.friends
                strongself.reloadData()
                
                if shouldAnimate {
                    strongself.animate()
                }
            }
        }
    }
    
    func animate() {
        UIView.animate(views: visibleCells,
                       animations: [],
                       initialAlpha: 0.5,
                       finalAlpha: 1.0,
                       duration: 0.3)
    }

}

extension FriendsTableView: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredDatasource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserTableViewCell.reuseIdentifier, for: indexPath) as! UserTableViewCell
        cell.user = filteredDatasource[indexPath.row]
        
        friendsTableViewDelegate?.tableView(self, willRenderCell: cell, AtIndexPath: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < filteredDatasource.count else { return }
        
        let friend = filteredDatasource[indexPath.row]
        
        AnalyticsManager.track(event: .friendSelected, withParameters: ["friend": friend.identifier])

        let viewController = UIStoryboard(name: AppConstants.Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: ChatViewController.storyboardIdentifier) as! ChatViewController
        viewController.user = friend
        NavigationManager.shared.push(viewController)
    }
}
