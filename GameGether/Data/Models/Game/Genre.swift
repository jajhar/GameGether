//
//  Genre.swift
//  GameGether
//
//  Created by James Ajhar on 8/27/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import Foundation
import CoreData

protocol Genre: class {
    var identifier: String { get set }
    var title: String { get set }
}

extension Genre {
    
    func update(fromGenre genre: Genre) {
        self.identifier = genre.identifier
        self.title = genre.title
    }
}

class GenreObject: Genre {
    var identifier: String = ""
    var title: String = ""
    
    convenience init(json: JSONDictionary) {
        self.init()
        self.identifier = json["id"] as? String ?? json["_id"] as? String ?? ""
        self.title = json["title"] as? String ?? ""
    }
}

extension GenreObject: Hashable {
    static func == (lhs: GenreObject, rhs: GenreObject) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

class GenreMO: NSManagedObject, Genre {
    @NSManaged var identifier: String
    @NSManaged var title: String
}
