//
//  APIRequestProtocol.swift
//  App
//
//  Created by James on 4/26/18.
//  Copyright © 2018 James. All rights reserved.
//

import Foundation
import KeychainSwift

protocol APIRequestProtocol {
    
    static var baseURL: URL { get }

    var methodType: RequestType { get }
    var path: String { get }
}

extension APIRequestProtocol {
    
    func request() -> URLRequest? {
        
        guard let path = path.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
            let url = URL(string: "\(Self.baseURL)\(path)") else {
                GGLog.error("\(#function): Invalid URL: \(Self.baseURL)\(self.path)")
                return nil
        }
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = methodType.rawValue
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let keychain = KeychainSwift()
        if let token = keychain.get(AppConstants.Keychain.remoteTokenKey) {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request as URLRequest
    }
}
