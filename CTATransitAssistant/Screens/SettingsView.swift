//
//  SettingsView.swift
//  CTA Transit Assistant
//
//  Screen 5: Notifications, operator mode toggle, accessibility
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("operatorModeEnabled") private var operatorModeEnabled = false
    @AppStorage("largeTextEnabled") private var largeTextEnabled = false
    @AppStorage("audioPreferred") private var audioPreferred = true
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Push Arrival Alerts", isOn: $notificationsEnabled)
                    Toggle("Audio-First (Speak on Load)", isOn: $audioPreferred)
                } header: {
                    Text("Notifications")
                }
                
                Section {
                    Toggle("Operator Mode", isOn: $operatorModeEnabled)
                        .onChange(of: operatorModeEnabled) { _, enabled in
                            appState.isOperatorMode = enabled
                        }
                } header: {
                    Text("Mode")
                } footer: {
                    Text("Operator mode shows line/run selection and schedule info.")
                }
                
                Section {
                    Toggle("Larger Text", isOn: $largeTextEnabled)
                    Toggle("Prioritize Audio Announcements", isOn: $audioPreferred)
                } header: {
                    Text("Accessibility")
                }
                
                Section {
                    Button("Unpair Glasses", role: .destructive) {
                        appState.isGlassesPaired = false
                        appState.metaDATService.disconnect()
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .onAppear {
            appState.isOperatorMode = operatorModeEnabled
        }
    }
}
