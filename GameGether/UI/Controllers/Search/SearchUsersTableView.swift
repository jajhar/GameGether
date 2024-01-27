//
//  SearchUsersTableView.swift
//  GameGether
//
//  Created by James Ajhar on 8/23/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

class SearchUsersTableView: UITableView {
    
    // MARK: Properties
    private(set) var users = [User]()
    var selectedUsers = [User]() {
        didSet {
            reloadData()
        }
    }

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
        separatorStyle = .none
        allowsSelection = true
        register(UINib(nibName: "UserTableViewCell", bundle: nil),
                 forCellReuseIdentifier: UserTableViewCell.reuseIdentifier)
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = 44
    }
    
    func searchForUsers(withIGN ign: String, andIGNCount count: Int? = nil) {

        let spinner = displaySpinner()

        DataCoordinator.shared.search(forUsersWithIGN: ign, andIGNCount: count) { [weak self] (users, error) in
            performOnMainThread {
                guard let strongself = self, error == nil, let users = users else {
                    GGLog.error("\(String(describing: error))")
                    self?.removeSpinner(spinner: spinner)
                    return
                }

                strongself.removeSpinner(spinner: spinner)
                strongself.users = users
                strongself.reloadData()
            }
        }
    }
    
    func resetDataSource(removeSelectedUsers: Bool = true) {
        users.removeAll()
        
        if removeSelectedUsers {
            selectedUsers.removeAll()
        }
        
        reloadData()
    }
}

extension SearchUsersTableView: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserTableViewCell.reuseIdentifier, for: indexPath) as! UserTableViewCell
        cell.user = users[indexPath.row]
        cell.showsCheckMarkButton = true
        cell.showsStatusLabel = false
        cell.checkMarkButton.isSelected = selectedUsers.contains(where: { $0.identifier == users[indexPath.row].identifier })
        
        return cell
    }
}

