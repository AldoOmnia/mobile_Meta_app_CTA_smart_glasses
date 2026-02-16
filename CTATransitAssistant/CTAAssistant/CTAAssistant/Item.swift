//
//  Item.swift
//  CTAAssistant
//
//  Created by Aldo Petruzzelli on 2/16/26.
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
