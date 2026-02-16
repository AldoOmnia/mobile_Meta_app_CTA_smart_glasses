//
//  CTAArrival.swift
//  CTA Transit Assistant
//

import Foundation

struct CTAArrival: Identifiable {
    let id = UUID()
    let route: String
    let destination: String
    let predictionMinutes: Int
    let runNumber: String?
    
    var spokenSummary: String {
        "\(route) Line to \(destination), \(predictionMinutes) minute\(predictionMinutes == 1 ? "" : "s")"
    }
}
