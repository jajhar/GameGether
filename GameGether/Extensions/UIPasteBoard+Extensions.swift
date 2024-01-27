//
//  UIPasteBoard+Extensions.swift
//  App
//
//  Created by James on 4/26/18.
//  Copyright © 2018 James. All rights reserved.
//

import UIKit
import SDWebImage

extension UIPasteboard {
    
    func copyImage(atURL imageURL: URL, completion: ((Error?) -> Void)? = nil) {
        
        SDWebImageDownloader.shared().downloadImage(with: imageURL, options: [], progress: nil) { (image, data, error, fromCache) in
            
            performOnMainThread {
                
                guard error == nil else {
                    completion?(error)
                    return
                }
                
                UIPasteboard.general.image = image
                completion?(nil)
            }
        }
    }
}
