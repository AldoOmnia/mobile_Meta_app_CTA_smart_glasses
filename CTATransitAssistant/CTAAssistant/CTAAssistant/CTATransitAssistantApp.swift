//
//  CTATransitAssistantApp.swift
//  CTA Transit Assistant
//
//  Hands-free CTA 'L' train arrival info on Meta AI Glasses.
//

import SwiftUI
import MWDATCore

@main
struct CTATransitAssistantApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        configureWearables()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .onOpenURL { url in
                    handleMetaCallback(url: url)
                }
        }
    }
    
    private func configureWearables() {
        do {
            try Wearables.configure()
        } catch {
            #if DEBUG
            print("[CTA] Wearables configure failed: \(error)")
            #endif
        }
    }
    
    private func handleMetaCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.queryItems?.contains(where: { $0.name == "metaWearablesAction" }) == true else {
            return
        }
        Task {
            do {
                _ = try await Wearables.shared.handleUrl(url)
            } catch {
                #if DEBUG
                print("[CTA] Meta callback error: \(error)")
                #endif
                await MainActor.run {
                    appState.metaDATService.setLastError(error.localizedDescription)
                }
            }
        }
    }
}
