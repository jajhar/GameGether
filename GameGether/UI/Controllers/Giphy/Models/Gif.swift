//
//  Gif.swift
//  GameGether
//
//  Created by James Ajhar on 1/21/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

struct Gif {
    var mediaURL: URL?
    var size: CGSize = .zero
    
    var jsonValue: JSONDictionary {
        return [
            "mediaUrl": mediaURL?.absoluteString ?? "",
            "width": size.width,
            "height": size.height
        ]
    }
    
    init(mediaURL: URL?, size: CGSize = .zero) {
        self.mediaURL = mediaURL
        self.size = size
    }
    
    init(json: JSONDictionary) {
        
        if let urlString = json["mediaUrl"] as? String, let url = URL(string: urlString) {
            mediaURL = url
        }
        
        if let width = json["width"] as? Double, let height = json["height"] as? Double {
            size = CGSize(width: width, height: height)
        }
    }
}
