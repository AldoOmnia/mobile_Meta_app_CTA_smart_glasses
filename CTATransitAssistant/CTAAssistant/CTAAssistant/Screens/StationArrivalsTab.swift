//
//  StationArrivalsTab.swift
//  CTA Transit Assistant
//
//  Combines Station Select (Screen 2) + Arrivals (Screen 3)
//

import SwiftUI

struct StationArrivalsTab: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            if appState.selectedStation != nil {
                ArrivalsView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Change Station") {
                                appState.selectedStation = nil
                            }
                        }
                    }
            } else {
                StationSelectView()
            }
        }
    }
}
