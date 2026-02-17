//
//  CTAStation.swift
//  CTA Transit Assistant
//

import CoreLocation

struct CTAStation: Identifiable, Hashable {
    let id: String
    let mapId: String
    let stationName: String
    let latitude: Double
    let longitude: Double
    let routes: [String]  // e.g. ["Red", "Blue"]
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var displayName: String {
        "\(stationName) (\(routes.joined(separator: ", ")))"
    }
}
