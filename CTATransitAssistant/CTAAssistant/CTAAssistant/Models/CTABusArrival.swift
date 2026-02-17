//
//  CTABusArrival.swift
//  CTA Transit Assistant
//
//  Bus arrival prediction from CTA Bus Tracker API.
//

import Foundation

struct CTABusArrival: Identifiable {
    let id = UUID()
    let route: String
    let destination: String
    let predictionMinutes: Int
    let stopName: String?
    
    var spokenSummary: String {
        "Route \(route) to \(destination), \(predictionMinutes) minute\(predictionMinutes == 1 ? "" : "s")"
    }
}
