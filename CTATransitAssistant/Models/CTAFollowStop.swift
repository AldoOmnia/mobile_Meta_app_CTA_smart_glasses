//
//  CTAFollowStop.swift
//  CTA Transit Assistant
//

import Foundation

struct CTAFollowStop: Identifiable {
    let id = UUID()
    let stopId: String
    let stopName: String
    let arrivalTime: Date?
    
    var spokenSummary: String {
        if let time = arrivalTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "\(stopName) at \(formatter.string(from: time))"
        }
        return stopName
    }
}
