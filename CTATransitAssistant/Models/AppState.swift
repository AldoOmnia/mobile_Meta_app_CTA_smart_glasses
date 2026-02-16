//
//  AppState.swift
//  CTA Transit Assistant
//

import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var isGlassesPaired = false
    @Published var isOperatorMode = false
    @Published var selectedStation: CTAStation?
    @Published var arrivals: [CTAArrival] = []
    @Published var currentRunNumber: String?
    
    var ctaService = CTAService()
    var metaDATService = MetaDATService()
    var locationService = LocationService()
}
