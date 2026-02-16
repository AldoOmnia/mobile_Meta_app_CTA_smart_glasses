//
//  CTATransitAssistantApp.swift
//  CTA Transit Assistant
//
//  Hands-free CTA 'L' train arrival info on Meta AI Glasses.
//

import SwiftUI

@main
struct CTATransitAssistantApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
