//
//  AppState.swift
//  CTA Transit Assistant
//

import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isGlassesPaired = false
    @Published var userRoleSelected = false  // Rider vs Operator, shown after pairing
    @Published var isOperatorMode = false
    @Published var selectedStation: CTAStation?
    @Published var previousStation: CTAStation?
    @Published var arrivals: [CTAArrival] = []
    @Published var currentRunNumber: String?
    
    let ctaService: CTAService
    let busService: CTABusService
    let metaDATService: MetaDATService
    let locationService: LocationService
    
    private var metaDATCancellable: AnyCancellable?
    
    init(
        ctaService: CTAService,
        busService: CTABusService,
        metaDATService: MetaDATService,
        locationService: LocationService
    ) {
        self.ctaService = ctaService
        self.busService = busService
        self.metaDATService = metaDATService
        self.locationService = locationService
        metaDATCancellable = metaDATService.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
    }
    
    convenience init() {
        self.init(
            ctaService: CTAService(),
            busService: CTABusService(),
            metaDATService: MetaDATService(),
            locationService: LocationService()
        )
    }
}
