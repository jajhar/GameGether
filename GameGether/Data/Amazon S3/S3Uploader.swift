//
//  S3Uploader.swift
//  GameGether
//
//  Created by James Ajhar on 6/28/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import Foundation
import AWSS3

enum S3ContentType: String {
    case image = "image/jpeg"
    case video = "video/mp4"
    
    var typeExtension: String {
        switch self {
        case .image:
            return "jpeg"
        case .video:
            return "mp4"
        }
    }
}

class S3Uploader {
    
    /// Generates a unique string for this upload based on uuid and the current date/time
    ///
    /// - Returns: A (probably) unique string
    private func generateKey() -> String {
        let uuid = UUID().uuidString
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let currentDateAsString = formatter.string(from: Date())
        return "\(uuid)-\(currentDateAsString)"
    }
    
    func upload(data: Data,
                contentType: S3ContentType,
                progress: AWSS3TransferUtilityProgressBlock? = nil,
                completion: @escaping (URL?, Error?) -> Void) {
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = progress
        
        let transferUtility = AWSS3TransferUtility.default()
        let uniqueKey = "\(generateKey()).\(contentType.typeExtension)".urlEncoded() ?? ""
        let finishedS3URL = URL(string: "\(AppConstants.AWS.cdn)/\(uniqueKey)")

        var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                if let error = error {
                    GGLog.error("\(String(describing: error.localizedDescription))")
                    completion(nil, error)
                    return
                }
                
                completion(finishedS3URL, nil)
            })
        }
        
        transferUtility.uploadData(data,
                                   bucket: AppConstants.AWS.s3Bucket,
                                   key: uniqueKey,
                                   contentType: contentType.rawValue,
                                   expression: expression,
                                   completionHandler: completionHandler).continueWith {
                                    (task) -> Any? in
                                    if let error = task.error {
                                        GGLog.error("Error: \(error.localizedDescription)")
                                    }
                                    
                                    if let _ = task.result {
                                        // Do something with uploadTask.
                                    }
                                    return nil;
        }
    }

}
