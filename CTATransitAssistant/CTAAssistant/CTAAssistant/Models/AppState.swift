//
//  AppState.swift
//  CTA Transit Assistant
//

import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isGlassesPaired = false
    @Published var isOperatorMode = false
    @Published var selectedStation: CTAStation?
    @Published var arrivals: [CTAArrival] = []
    @Published var currentRunNumber: String?
    
    let ctaService: CTAService
    let metaDATService: MetaDATService
    let locationService: LocationService
    
    init(
        ctaService: CTAService,
        metaDATService: MetaDATService,
        locationService: LocationService
    ) {
        self.ctaService = ctaService
        self.metaDATService = metaDATService
        self.locationService = locationService
    }
    
    convenience init() {
        self.init(
            ctaService: CTAService(),
            metaDATService: MetaDATService(),
            locationService: LocationService()
        )
    }
}
