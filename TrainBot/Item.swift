//
//  Item.swift
//  TrainBot
//
//  Created by Luca Moldovan on 05.05.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
