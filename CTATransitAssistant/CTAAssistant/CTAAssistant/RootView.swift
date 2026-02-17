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
            } else if !appState.userRoleSelected {
                RoleSelectView()
            } else {
                GlassesActivatorView()
            }
        }
        .animation(.easeInOut, value: appState.isGlassesPaired)
        .animation(.easeInOut, value: appState.userRoleSelected)
    }
}

// High-contrast blue for tab icons (matches RayBan glasses / CTA logo)
private let tabTintBlue = Color(red: 0, green: 0.55, blue: 1.0)

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SchedulesTabView()
                .tabItem { Label("Schedules", systemImage: "train.side.front.car") }
                .tag(0)
            MapsView()
                .tabItem { Label("Map", systemImage: "map.fill") }
                .tag(1)
            FollowTrainView()
                .tabItem { Label("Follow Train", systemImage: "location.fill") }
                .tag(2)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(3)
            if appState.isOperatorMode {
                OperatorModeView()
                    .tabItem { Label("Operator", systemImage: "person.badge.key.fill") }
                    .tag(4)
            }
        }
        .tint(tabTintBlue)
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
