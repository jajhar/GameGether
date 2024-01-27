//
//  Base.swift
//  GameGether
//
//  Created by James Ajhar on 2/13/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import Foundation

protocol NotificationName {
    var name: Notification.Name { get }
}

extension RawRepresentable where RawValue == String, Self: NotificationName {
    var name: Notification.Name {
        get {
            return Notification.Name(self.rawValue)
        }
    }
}
