//
//  RemoteCoordinator.swift
//  App
//
//  Created by James on 4/26/18.
//  Copyright © 2018 James. All rights reserved.
//

import Foundation

typealias JSONDictionary = [String: Any]

struct RemoteCoordinator: RemoteCoordinatorProtocol {
        
    let session: URLSession = URLSession.shared
}
