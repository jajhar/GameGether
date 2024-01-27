//
//  RemoteError.swift
//  App
//
//  Created by James on 4/26/18.
//  Copyright © 2018 James. All rights reserved.
//

import Foundation

enum RemoteError: Error, Equatable, LocalizedError {
    
    case apiError(message: String?, errorCode: Int?)
    
    var errorCode: Int {
        switch self {
        case .apiError(_, let errorCode): return errorCode ?? -1
        }
    }
    
    var description: String {
        switch self {
        case .apiError(let message, _):
            
            if let message = message {
                return message
            } else {
                return "An unknown error occurred"
            }
        }
    }

    var errorDescription: String? {
        get {
            return self.description
        }
    }
}

func == (lhs: RemoteError, rhs: RemoteError) -> Bool {
    switch (lhs, rhs) {
    case (.apiError, .apiError):
        return lhs.localizedDescription == rhs.localizedDescription && lhs.errorCode == rhs.errorCode
    }
}
