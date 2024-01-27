//
//  Tag.swift
//  GameGether
//
//  Created by James Ajhar on 9/13/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

enum TagType: Int {
    case teamSize
    case device
    case gameMode
    case location
    case skill
    case communication
    case spectrum
    case personality
    case custom
    
    var stringValue: String {
        switch self {
        case .teamSize:
            return "TEAM_SIZE"
        case .device:
            return "DEVICE"
        case .gameMode:
            return "GAME_MODE"
        case .location:
            return "LOCATION"
        case .skill:
            return "SKILL"
        case .communication:
            return "COMMUNICATION"
        case .spectrum:
            return "SPECTRUM"
        case .personality:
            return "PERSONALITY"
        case .custom:
            return "CUSTOM"
        }
    }
    
    static var totalTypes: Int {
        return allTypes.count
    }
    
    static var allTypes: [TagType] {
        return [.teamSize, .device, .gameMode, .location, .skill, .communication, .spectrum, .personality, .custom]
    }
}

protocol Tag {
    var identifier: String { get }
    var title: String { get }
    var type: TagType { get }
    var priority: Int16 { get }
    var size: Int16 { get }
    var nestedTags: [Tag]? { get }
}

extension Array where Iterator.Element == Tag {

    var hashedValue: String {
        let tags = compactMap({ $0.identifier })
        let sortedTags = tags.sorted()
        let tagHash = sortedTags.joined(separator: "_")
        return tagHash
    }
    
    var isPlatformTagSelected: Bool {
        return filter({ $0.type == .device }).count > 0
    }
    
    var isGameModeTagSelected: Bool {
        return filter({ $0.type == .gameMode }).count > 0
    }
    
    var marqueeText: String {
        let sortedTags = sorted(by: { $0.type.rawValue < $1.type.rawValue })
        let tags = sortedTags.compactMap({ $0.title })
        let tagHash = tags.joined(separator: " ")
        return tagHash
    }
    
    mutating func sortByType() {
        self = sorted(by: { (left, right) -> Bool in
            return left.type.rawValue < right.type.rawValue
        })
    }
    
    mutating func sortByPriority() {
        self = sorted(by: { (left, right) -> Bool in
            return left.priority < right.priority
        })
    }
    
    func isEqual(to tags: [Tag]) -> Bool {
        var lhs = compactMap({ $0.title })
        lhs.sort()
        
        var rhs = tags.compactMap({ $0.title })
        rhs.sort()

        return lhs == rhs
    }
    
    func sizeTags() -> [Tag] {
        var sizeTags = filter({ $0.size > 0 })
        forEach({
            // Include nested tags
            let nestedSizeTags = $0.nestedTags?.filter({ $0.size > 0 }) ?? []
            
            nestedSizeTags.forEach { (nestedSizeTag) in
                // Remove duplicates!
                guard !sizeTags.contains(where: { $0.identifier == nestedSizeTag.identifier }) else { return }
                sizeTags.append(nestedSizeTag)
            }
        })
        return sizeTags
    }
    
    func gameModeTag() -> Tag? {
        return filter({ $0.type == .gameMode }).first
    }
}
