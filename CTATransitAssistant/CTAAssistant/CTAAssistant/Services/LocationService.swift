//
//  LocationService.swift
//  CTA Transit Assistant
//
//  Core Location for nearest station detection.
//

import Foundation
internal import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?
    @Published var nearestStation: CTAStation?
    
    private let manager = CLLocationManager()
    private let stationList = CTAStationsRepository.shared
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
    
    func findNearestStation(from location: CLLocation) -> CTAStation? {
        let stations = stationList.allStations
        return stations.min(by: { s1, s2 in
            location.distance(from: CLLocation(latitude: s1.latitude, longitude: s1.longitude)) <
            location.distance(from: CLLocation(latitude: s2.latitude, longitude: s2.longitude))
        })
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.lastLocation = location
            self.nearestStation = findNearestStation(from: location)
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }
}
