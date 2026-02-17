//
//  CTAStationsRepository.swift
//  CTA Transit Assistant
//
//  CTA station list with map IDs for API calls.
//  Subset of major 'L' stations; extend as needed.
//

import Foundation
import CoreLocation

final class CTAStationsRepository {
    static let shared = CTAStationsRepository()
    
    let allStations: [CTAStation] = [
        // Red Line
        CTAStation(id: "40900", mapId: "40900", stationName: "Howard", latitude: 42.019063, longitude: -87.672892, routes: ["Red", "Yellow", "Purple"]),
        CTAStation(id: "40380", mapId: "40380", stationName: "Roosevelt", latitude: 41.867405, longitude: -87.627402, routes: ["Red", "Orange", "Green"]),
        CTAStation(id: "41420", mapId: "41420", stationName: "95th/Dan Ryan", latitude: 41.722377, longitude: -87.624342, routes: ["Red"]),
        CTAStation(id: "41660", mapId: "41660", stationName: "Grand", latitude: 41.891189, longitude: -87.628156, routes: ["Red"]),
        CTAStation(id: "41820", mapId: "41820", stationName: "Jackson", latitude: 41.878153, longitude: -87.627596, routes: ["Red"]),
        CTAStation(id: "40350", mapId: "40350", stationName: "Lake", latitude: 41.884809, longitude: -87.627813, routes: ["Red"]),
        CTAStation(id: "41490", mapId: "41490", stationName: "Monroe", latitude: 41.880703, longitude: -87.627696, routes: ["Red"]),
        CTAStation(id: "41090", mapId: "41090", stationName: "Harrison", latitude: 41.874039, longitude: -87.627479, routes: ["Red"]),
        CTAStation(id: "40670", mapId: "40670", stationName: "Lawrence", latitude: 41.969059, longitude: -87.658493, routes: ["Red"]),
        CTAStation(id: "41360", mapId: "41360", stationName: "State/Lake", latitude: 41.885574, longitude: -87.627635, routes: ["Red", "Green", "Brown", "Orange", "Pink", "Purple"]),
        // Blue Line
        CTAStation(id: "40570", mapId: "40570", stationName: "O'Hare", latitude: 41.982819, longitude: -87.904223, routes: ["Blue"]),
        CTAStation(id: "40490", mapId: "40490", stationName: "Washington", latitude: 41.883164, longitude: -87.629440, routes: ["Blue"]),
        CTAStation(id: "40170", mapId: "40170", stationName: "Clark/Lake", latitude: 41.885737, longitude: -87.630886, routes: ["Blue", "Brown", "Green", "Orange", "Pink", "Purple"]),
        // Brown Line
        CTAStation(id: "41200", mapId: "41200", stationName: "Kimball", latitude: 41.967961, longitude: -87.713065, routes: ["Brown"]),
        // Green Line
        CTAStation(id: "40020", mapId: "40020", stationName: "Ashland/63rd", latitude: 41.779471, longitude: -87.663766, routes: ["Green"]),
        // Orange Line
        CTAStation(id: "41050", mapId: "41050", stationName: "Midway", latitude: 41.786457, longitude: -87.737875, routes: ["Orange"]),
        // Pink Line
        CTAStation(id: "41330", mapId: "41330", stationName: "54th/Cermak", latitude: 41.853773, longitude: -87.756692, routes: ["Pink"]),
        // Purple Line
        CTAStation(id: "41120", mapId: "41120", stationName: "Linden", latitude: 42.073153, longitude: -87.69073, routes: ["Purple"]),
    ]
    
    func stations(for routes: [String]) -> [CTAStation] {
        allStations.filter { station in
            station.routes.contains { routes.contains($0) }
        }
    }
    
    func station(byMapId mapId: String) -> CTAStation? {
        allStations.first { $0.mapId == mapId }
    }
    
    /// Look up station by name (case-insensitive, contains). For alert-to-location mapping.
    func station(byName name: String) -> CTAStation? {
        let lower = name.lowercased()
        return allStations.first { $0.stationName.lowercased().contains(lower) || lower.contains($0.stationName.lowercased()) }
    }
    
    private init() {}
}
