//
//  Game.swift
//  GameGether
//
//  Created by James Ajhar on 6/20/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

protocol Game: class {
    var identifier: String { get }
    var title: String { get }
    var iconImageURL: URL? { get }
    var tagThemeImageURL: URL? { get }
    var gameSelectionImageURL: URL? { get }
    var isFavorite: Bool { get }
    var gamerTag: String { get set }
    var headerColor: String? { get }
    var isCrossPlatform: Bool { get }
    var genres: [Genre] { get }
}

extension Array where Iterator.Element == Game {

    mutating func removeGame(_ game: Game) {
        if let index = firstIndex(where: { $0.identifier == game.identifier }) {
            remove(at: index)
        }
    }
    
    var genres: [Genre] {
        var set = Set<GenreObject>()
        
        forEach { (game) in
            game.genres.forEach{ (genre) in
                guard let genre = genre as? GenreObject else { return }
                set.insert(genre)
            }
        }

        return Array<GenreObject>(set)
    }
}
