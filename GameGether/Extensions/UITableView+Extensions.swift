//
//  UITableView+Extensions.swift
//  GameGether
//
//  Created by James Ajhar on 8/6/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

extension UITableView {
    
    func scrollToBottom(ofSection section: Int = 0, animated: Bool = true){
        performOnMainThread {
            guard let row = self.dataSource?.tableView(self, numberOfRowsInSection: section), row > 0 else { return }
            let indexPath = IndexPath(row: row - 1, section: section)
            self.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }
}
