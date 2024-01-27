//
//  GameMO.swift
//  GameGether
//
//  Created by James Ajhar on 6/20/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import CoreData

class GameMO: NSManagedObject, Game {
    
    @NSManaged var identifier: String
    @NSManaged var title: String
    @NSManaged var gamerTag: String
    @NSManaged var headerColor: String?
    @NSManaged var iconImageURL: URL?
    @NSManaged var updatedAt: Date
    @NSManaged var isFavorite: Bool
    @NSManaged var tagThemeImageURL: URL?
    @NSManaged var gameSelectionImageURL: URL?
    @NSManaged var isCrossPlatform: Bool
    
    // MARK: Relationships
    @NSManaged public var genresRelationship: Set<GenreMO>?

    var genres: [Genre] {
        get {
            guard let relationships = genresRelationship else { return [] }
            
            var threadSafeObjects = [Genre]()
            for genreMO in relationships {
                let object = GenreObject()
                object.update(fromGenre: genreMO)
                threadSafeObjects.append(object)
            }
            return threadSafeObjects
        }
        set {
            assertionFailure("This object does not support setting of the genres variable")
        }
    }

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    /// Update Entity Properties from Game protocol
    ///
    /// - Parameter model: The Game model to update from
    func update(fromGameModel model: Game) {
        self.identifier = model.identifier
        self.title = model.title
        self.iconImageURL = model.iconImageURL
        self.isFavorite = model.isFavorite
        self.tagThemeImageURL = model.tagThemeImageURL
        self.gameSelectionImageURL = model.gameSelectionImageURL
        self.gamerTag = model.gamerTag
        self.headerColor = model.headerColor
        self.isCrossPlatform = model.isCrossPlatform
        self.updatedAt = Date()
    }
}
