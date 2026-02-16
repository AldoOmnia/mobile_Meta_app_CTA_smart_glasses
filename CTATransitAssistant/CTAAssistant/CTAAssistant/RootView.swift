//
//  RootView.swift
//  CTA Transit Assistant
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if !appState.isGlassesPaired {
                PairingView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut, value: appState.isGlassesPaired)
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            StationArrivalsTab()
                .tabItem { Label("Arrivals", systemImage: "train.side.front.car") }
                .tag(0)
            FollowTrainView()
                .tabItem { Label("Follow Train", systemImage: "location.fill") }
                .tag(1)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
            if appState.isOperatorMode {
                OperatorModeView()
                    .tabItem { Label("Operator", systemImage: "person.badge.key.fill") }
                    .tag(3)
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
