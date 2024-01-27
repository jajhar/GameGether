//
//  LocalCoordinator+Tags.swift
//  GameGether
//
//  Created by James Ajhar on 9/13/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import CoreData

extension LocalCoordinator {
    
    func getTags(forGame gameId: String, completion: @escaping (([Tag]?, Error?) -> Void)) {
        
        let context = persistentContainer.viewContext
        
        context.perform {
            
            do {
                let request: NSFetchRequest<TagMO> = NSFetchRequest(entityName: "TagMO")
                
                request.predicate = NSPredicate(format: "gameId = %@ AND isFollowed = %@", gameId, NSNumber(value: false))

                let tags = try context.fetch(request)
                
                if let tag = tags.first,
                    let updatedAt = tag.updatedAt,
                    let date = Date().subtractSeconds(Constants.staleTagsCacheInterval),
                    date > updatedAt
                {
                    // cache is stale
                    completion(nil, nil)
                    return
                }
                
                var threadSafeTags = [Tag]()
                
                for tag in tags {
                    threadSafeTags.append(TagObject(fromTagMO: tag))
                }
                
                completion(threadSafeTags, nil)
                
            } catch {
                GGLog.error("Error: \(error)")
                completion(nil, error)
            }
        }
    }
    
    func saveTags(tags: [Tag], forGame gameId: String? = nil, completion: (([Tag]?, Error?) -> Void)?) {
        
        let context = persistentContainer.viewContext
        
        deleteAllTags { (error) in
            
            context.perform {
                
                do {                    
                    guard let description = NSEntityDescription.entity(forEntityName: "\(TagMO.self)", in: context) else {
                        completion?(nil, LocalCoordinatorError.userCreateFailed)
                        return
                    }
                    
                    var threadSafeTags = [Tag]()
                    for tag in tags {
                        // Create the tag
                        let tagMO = TagMO(entity: description, insertInto: context)
                        tagMO.update(fromModel: tag)
                        tagMO.gameId = gameId
                        
                        if let nestedTags = tag.nestedTags {
                            for nestedTag in nestedTags {
                                // Create the Tag Relationship
                                let nestedTagMO = TagMO.init(entity: description, insertInto: context)
                                nestedTagMO.update(fromModel: nestedTag)
                                tagMO.nestedTagsRelationship?.insert(nestedTagMO)
                            }
                        }
                        
                        threadSafeTags.append(TagObject(fromTagMO: tagMO))
                    }
                    
                    try context.save()
                    
                    completion?(threadSafeTags, nil)
                    
                } catch {
                    GGLog.error("Error: \(error)")
                    completion?(nil, error)
                }
            }
        }
    }
    
    func bookmarkTags(tags: [Tag], forGame gameId: String, completion: ((Error?) -> Void)?) {
        
        let context = persistentContainer.viewContext
        
        deleteAllBookmarks(forGameId: gameId) { (error) in
            
            context.perform {
                
                do {
                    guard let description = NSEntityDescription.entity(forEntityName: "\(TagBookmarkMO.self)", in: context) else {
                        completion?(nil)
                        return
                    }
                    
                    for tag in tags {
                        // Create the tag bookmark
                        let bookmarkMO = TagBookmarkMO(entity: description, insertInto: context)
                        bookmarkMO.gameId = gameId
                        bookmarkMO.tagId = tag.identifier
                    }
                    
                    try context.save()
                    
                    completion?(nil)
                    
                } catch {
                    GGLog.error("Error: \(error)")
                    completion?(error)
                }
            }
        }
    }
    
    func saveFollowedTags(followedTags: [TagsGroup], completion: (([TagsGroup]?, Error?) -> Void)?) {
        
        let context = persistentContainer.viewContext
        
        deleteAllFollowedTags { (error) in
            
            context.perform {
                
                do {
                    guard let description = NSEntityDescription.entity(forEntityName: "\(FollowedTagsMO.self)", in: context) else {
                        completion?(nil, LocalCoordinatorError.userCreateFailed)
                        return
                    }
                    
                    guard let tagDescription = NSEntityDescription.entity(forEntityName: "\(TagMO.self)", in: context) else {
                        completion?(nil, LocalCoordinatorError.userCreateFailed)
                        return
                    }
                    
                    var threadSafeTags = [TagsGroup]()
                    for followedTag in followedTags {
                        let followedTagMO = FollowedTagsMO(entity: description, insertInto: context)
                        followedTagMO.update(fromModel: followedTag)
                        
                        for tag in followedTag.tags {
                            let tagMO = TagMO(entity: tagDescription, insertInto: context)
                            tagMO.update(fromModel: tag)
                            tagMO.isFollowed = true
                            followedTagMO.tagsRelationship?.insert(tagMO)
                        }
                        
                        threadSafeTags.append(TagsGroupObject(fromFollowedTagsMO: followedTagMO))
                    }
                    
                    try context.save()
                    
                    completion?(threadSafeTags, nil)
                    
                } catch {
                    GGLog.error("Error: \(error)")
                    completion?(nil, error)
                }
            }
        }
    }
    
    func getFollowedTags(completion: @escaping (([TagsGroup]?, Error?) -> Void)) {
        
        let context = persistentContainer.viewContext
        
        context.perform {
            
            do {
                let request: NSFetchRequest<FollowedTagsMO> = NSFetchRequest(entityName: "\(FollowedTagsMO.self)")
                
                let followedTags = try context.fetch(request)
                
                guard followedTags.count > 0 else {
                    // Nothing followed
                    completion([], nil)
                    return
                }
                
                var threadSafeObjects = [TagsGroup]()
                for followedTag in followedTags {
                    threadSafeObjects.append(TagsGroupObject(fromFollowedTagsMO: followedTag))
                }
                
                completion(threadSafeObjects, nil)
                
            } catch {
                GGLog.error("Error: \(error)")
                completion(nil, error)
            }
        }
    }
    
    func getBookmarkedTags(forGame gameId: String, completion: @escaping (([Tag]?, Error?) -> Void)) {

        let context = persistentContainer.viewContext
        
        context.perform {
            
            do {
                let bookmarkRequest: NSFetchRequest<TagBookmarkMO> = NSFetchRequest(entityName: "TagBookmarkMO")
                bookmarkRequest.predicate = NSPredicate(format: "gameId = %@", gameId)
                
                let bookmarks = try context.fetch(bookmarkRequest)
                
                var tagIds = [String]()
                for bookmark in bookmarks {
                    tagIds.append(bookmark.tagId)
                }
                
                guard tagIds.count > 0 else {
                    // Nothing bookmarked
                    completion([], nil)
                    return
                }
                
                let tagRequest: NSFetchRequest<TagMO> = NSFetchRequest(entityName: "TagMO")
                tagRequest.predicate = NSPredicate(format: "ANY identifier IN %@ AND isFollowed = %@", tagIds, NSNumber(value: false))

                let tags = try context.fetch(tagRequest)

                var threadSafeTags = [Tag]()
                for tag in tags {
                    threadSafeTags.append(TagObject(fromTagMO: tag))
                }
                
                completion(threadSafeTags, nil)
                
            } catch {
                GGLog.error("Error: \(error)")
                completion(nil, error)
            }
        }
    }
    
    /// Deletes all Tags in the cache
    ///
    /// - Parameter completion: Called when all Tag objects have been deleted
    func deleteAllTags(_ completion: ((Error?) -> Void)? = nil) {
        
        let fetchRequest = NSFetchRequest<TagMO>(entityName: "TagMO")
        
        let context = persistentContainer.viewContext
        context.performAndWait { [weak self] in
            do {
                guard let strongSelf = self else {
                    completion?(LocalCoordinatorError.deallocated)
                    return
                }
                
                let results = try context.fetch(fetchRequest)
                results.forEach({
                    if !$0.isFollowed {
                        // Don't delete tags objects that are being used by the FollowedTags objects
                        context.delete($0)
                    }
                })
                
                strongSelf.saveContext()
                completion?(nil)
                
            } catch let error as NSError {
                GGLog.error("Error: \(error)")
                completion?(error)
            }
        }
    }
    
    /// Deletes all Followed Tags in the cache
    ///
    /// - Parameter completion: Called when all Followed Tag objects have been deleted
    func deleteAllFollowedTags(_ completion: ((Error?) -> Void)? = nil) {
        
        let fetchRequest = NSFetchRequest<FollowedTagsMO>(entityName: "\(FollowedTagsMO.self)")
        
        let context = persistentContainer.viewContext
        context.performAndWait { [weak self] in
            do {
                guard let strongSelf = self else {
                    completion?(LocalCoordinatorError.deallocated)
                    return
                }
                
                let results = try context.fetch(fetchRequest)
                results.forEach({
                    context.delete($0)
                })
                
                strongSelf.saveContext()
                completion?(nil)
                
            } catch let error as NSError {
                GGLog.error("Error: \(error)")
                completion?(error)
            }
        }
    }
    
    /// Deletes all Tag bookmarks in the cache
    ///
    /// - Parameter completion: Called when all bookmark objects have been deleted
    func deleteAllBookmarks(forGameId gameId: String? = nil, completion: ((Error?) -> Void)? = nil) {
        
        let fetchRequest = NSFetchRequest<TagBookmarkMO>(entityName: "TagBookmarkMO")
        
        if let gameId = gameId {
            fetchRequest.predicate = NSPredicate(format: "gameId = %@", gameId)
        }

        let context = persistentContainer.viewContext
        context.performAndWait { [weak self] in
            do {
                guard let strongSelf = self else {
                    completion?(LocalCoordinatorError.deallocated)
                    return
                }
                
                let results = try context.fetch(fetchRequest)
                results.forEach({ context.delete($0) })
                
                strongSelf.saveContext()
                completion?(nil)
                
            } catch let error as NSError {
                GGLog.error("Error: \(error)")
                completion?(error)
            }
        }
    }
}
