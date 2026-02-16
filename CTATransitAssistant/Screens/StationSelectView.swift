//
//  StationSelectView.swift
//  CTA Transit Assistant
//
//  Screen 2: Auto-detect nearest station OR manual pick from list
//

import SwiftUI

struct StationSelectView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    
    private var filteredStations: [CTAStation] {
        let stations = CTAStationsRepository.shared.allStations
        if searchText.isEmpty { return stations }
        return stations.filter {
            $0.stationName.localizedCaseInsensitiveContains(searchText) ||
            $0.routes.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        List {
                if appState.locationService.authorizationStatus == .authorizedWhenInUse,
                   let nearest = appState.locationService.nearestStation {
                    Section {
                        Button {
                            appState.selectedStation = nearest
                        } label: {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading) {
                                    Text("Nearest: \(nearest.stationName)")
                                        .font(.headline)
                                    Text(nearest.routes.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Near You")
                    }
                }
                
                Section {
                    ForEach(filteredStations) { station in
                        Button {
                            appState.selectedStation = station
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(station.stationName)
                                        .font(.headline)
                                    Text(station.routes.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("All Stations")
                }
            }
        .searchable(text: $searchText, prompt: "Search stations")
        .navigationTitle("Select Station")
        .onAppear {
            appState.locationService.requestAuthorization()
            appState.locationService.startUpdatingLocation()
        }
        .onDisappear {
            appState.locationService.stopUpdatingLocation()
        }
    }
}
