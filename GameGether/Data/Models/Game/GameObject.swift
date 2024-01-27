//
//  GameObject.swift
//  GameGether
//
//  Created by James Ajhar on 6/20/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation

class GameObject: Game {
    
    private(set) var identifier: String = ""
    private(set) var title: String = ""
    private(set) var iconImageURL: URL?
    private(set) var tagThemeImageURL: URL?
    private(set) var gameSelectionImageURL: URL?
    private(set) var headerColor: String?
    private(set) var isCrossPlatform: Bool = false
    private(set) var genres = [Genre]()

    var isFavorite: Bool = false
    var gamerTag: String = ""

    static func parseJSON(_ json: [String: Any]) -> GameObject {
    
        let game = GameObject()
        game.identifier = json["_id"] as? String ?? ""
        game.title = json["title"] as? String ?? ""
        game.isFavorite = json["isFavorite"] as? Bool ?? false
        game.gamerTag = json["gamerTag"] as? String ?? ""
        game.headerColor = json["headerColor"] as? String
        game.isCrossPlatform = json["isCrossPlatform"] as? Bool ?? false
        
        if let genres = json["genres"] as? [JSONDictionary] {
            for genreJSON in genres {
                game.genres.append(GenreObject(json: genreJSON))
            }
        }
        
        if let url = json["iconImageURL"] as? String {
            game.iconImageURL = URL(string: url)
        }
        
        if let url = json["tagThemeImageURL"] as? String {
            game.tagThemeImageURL = URL(string: url)
        }
        
        if let url = json["gameSelectionImageURL"] as? String {
            game.gameSelectionImageURL = URL(string: url)
        }
        
        return game
    }
    
    convenience init(fromGameMO gameMO: GameMO) {
        self.init()
        self.identifier = gameMO.identifier
        self.title = gameMO.title
        self.iconImageURL = gameMO.iconImageURL
        self.isFavorite = gameMO.isFavorite
        self.tagThemeImageURL = gameMO.tagThemeImageURL
        self.gameSelectionImageURL = gameMO.gameSelectionImageURL
        self.gamerTag = gameMO.gamerTag
        self.headerColor = gameMO.headerColor
        self.isCrossPlatform = gameMO.isCrossPlatform
        self.genres = gameMO.genres
    }
}

extension Game {
    
    var jsonValue: JSONDictionary {
        var dictionary = JSONDictionary()
        dictionary["_id"] = identifier
        dictionary["title"] = title
        dictionary["iconImageURL"] = iconImageURL?.absoluteString ?? ""
        dictionary["tagThemeImageURL"] = tagThemeImageURL?.absoluteString ?? ""
        dictionary["isFavorite"] = isFavorite
        dictionary["gamerTag"] = gamerTag
        dictionary["headerColor"] = headerColor
        dictionary["isCrossPlatform"] = isCrossPlatform
        return dictionary
    }
}
