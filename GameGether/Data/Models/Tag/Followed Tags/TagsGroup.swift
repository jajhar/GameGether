//
//  TagsGroup.swift
//  GameGether
//
//  Created by James Ajhar on 9/17/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

protocol TagsGroup {
    var identifier: String { get }
    var gameId: String { get }
    var tags: [Tag] { get }
    var users: [User] { get }
}

extension Array where Iterator.Element == TagsGroup {
    
    func containsTags(tags: [Tag], forGame gameId: String) -> Bool {
        let filtered = filter({ $0.gameId == gameId })
        return filtered.filter({ tags.isEqual(to: $0.tags )}).first != nil
    }
    
    func group(withTags tags: [Tag], forGame gameId: String) -> TagsGroup? {
        let filtered = filter({ $0.gameId == gameId })
        return filtered.filter({ tags.isEqual(to: $0.tags )}).first
    }
}
