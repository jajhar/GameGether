//
//  RemoteCoordinatorProtocol.swift
//  App
//
//  Created by James on 4/26/18.
//  Copyright © 2018 James. All rights reserved.
//

import Foundation

protocol RemoteCoordinatorProtocol {
    
    var session: URLSession { get }

    func parse<T: Decodable>(jsonData data: Data, expectedType type: T.Type) -> T?
    func send(request urlRequest: URLRequest, completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void)
}

extension RemoteCoordinatorProtocol {
    
    func send(request urlRequest: URLRequest, completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        
        session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            
            let response = response as? HTTPURLResponse
            
            completion(data, response, error)
            
        }).resume()
    }
    
    func parse<T: Decodable>(jsonData data: Data, expectedType type: T.Type) -> T? {
        
        let decoder = JSONDecoder()

        do {
            return try decoder.decode(type.self, from: data)
        } catch {
            GGLog.error("Error parsing JSON: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func jsonParse(data: Data) -> Any? {
        
        do {
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            GGLog.error("Error parsing JSON: \(error.localizedDescription)")
        }
        
        return nil
    }
}
