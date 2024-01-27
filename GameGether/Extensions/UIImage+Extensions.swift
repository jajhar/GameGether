//
//  UIImage+Extensions.swift
//  GameGether
//
//  Created by James Ajhar on 6/30/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    static func imageWithImage(sourceImage: UIImage, scaledToWidth: CGFloat) -> UIImage {
        let oldWidth = sourceImage.size.width
        let scaleFactor = scaledToWidth / oldWidth
        
        let newHeight = sourceImage.size.height * scaleFactor
        let newWidth = oldWidth * scaleFactor
        
        UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
        sourceImage.draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func jpegRepresentation(compression: CGFloat = 1.0) -> Data? {
        return self.jpegData(compressionQuality: compression)
    }
}
