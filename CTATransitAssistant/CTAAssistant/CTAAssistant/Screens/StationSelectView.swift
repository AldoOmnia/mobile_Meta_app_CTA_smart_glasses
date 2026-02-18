//
//  StationSelectView.swift
//  CTA Transit Assistant
//
//  Screen 2: Auto-detect nearest station OR manual pick from list
//

import SwiftUI
import CoreLocation

struct StationSelectView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    var embeddedInScroll: Bool = false
    
    private var filteredStations: [CTAStation] {
        let stations = CTAStationsRepository.shared.allStations
        if searchText.isEmpty { return stations }
        return stations.filter {
            $0.stationName.localizedCaseInsensitiveContains(searchText) ||
            $0.routes.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    @ViewBuilder
    private var stationListContent: some View {
        if appState.locationService.authorizationStatus == .authorizedWhenInUse,
           let nearest = appState.locationService.nearestStation {
            Section {
                Button {
                    appState.selectedStation = nearest
                } label: {
                    stationRow(nearest, showLocation: true)
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
                    stationRow(station, showLocation: false)
                }
            }
        } header: {
            Text("All Stations")
        }
    }
    
    private func stationRow(_ station: CTAStation, showLocation: Bool) -> some View {
        HStack {
            Image(systemName: "train.side.front.car")
                .foregroundStyle(ctaLineColor(station.routes.first ?? ""))
                .frame(width: 28)
            if showLocation {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundStyle(CTAColors.blueLineBlue)
            }
            VStack(alignment: .leading) {
                Text(showLocation ? "Nearest: \(station.stationName)" : station.stationName)
                    .font(.headline)
                Text(station.routes.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var embeddedStationList: some View {
        if appState.locationService.authorizationStatus == .authorizedWhenInUse,
           let nearest = appState.locationService.nearestStation {
            VStack(alignment: .leading, spacing: 8) {
                Text("Near You")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                CTARouteDiagramRow(
                    station: nearest,
                    isFirst: true,
                    isLast: true,
                    showAccessibility: true,
                    onTap: { appState.selectedStation = nearest }
                )
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
        }
        VStack(alignment: .leading, spacing: 8) {
            Text("All Stations")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            LazyVStack(spacing: 0) {
                ForEach(Array(filteredStations.enumerated()), id: \.element.id) { index, station in
                    CTARouteDiagramRow(
                        station: station,
                        isFirst: index == 0,
                        isLast: index == filteredStations.count - 1,
                        showAccessibility: true,
                        onTap: { appState.selectedStation = station }
                    )
                }
            }
        }
    }
    
    var body: some View {
        Group {
            if embeddedInScroll {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Search stations", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 20)
                    embeddedStationList
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 24)
            } else {
                List {
                if appState.locationService.authorizationStatus == .authorizedWhenInUse,
                   let nearest = appState.locationService.nearestStation {
                    Section {
                        Button {
                            appState.selectedStation = nearest
                        } label: {
                            HStack {
                                Image(systemName: "train.side.front.car")
                                    .foregroundStyle(ctaLineColor(nearest.routes.first ?? ""))
                                    .frame(width: 28)
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundStyle(CTAColors.blueLineBlue)
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
                                Image(systemName: trainIcon(for: station.routes.first ?? ""))
                                    .foregroundStyle(ctaLineColor(station.routes.first ?? ""))
                                    .frame(width: 28)
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
            }
        }
        .modifier(ConditionalSearchable(show: !embeddedInScroll, text: $searchText, prompt: "Search stations"))
        .modifier(ConditionalNavigationTitle(show: !embeddedInScroll, title: "Select Station"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if appState.previousStation != nil {
                    Button("Back") {
                        appState.selectedStation = appState.previousStation
                    }
                }
            }
        }
        .onAppear {
            appState.locationService.requestAuthorization()
            appState.locationService.startUpdatingLocation()
        }
        .onDisappear {
            appState.locationService.stopUpdatingLocation()
        }
    }
    
    private func trainIcon(for route: String) -> String {
        "train.side.front.car"
    }
}

private struct ConditionalNavigationTitle: ViewModifier {
    let show: Bool
    let title: String
    func body(content: Content) -> some View {
        if show {
            content.navigationTitle(title)
        } else {
            content
        }
    }
}

private struct ConditionalSearchable: ViewModifier {
    let show: Bool
    @Binding var text: String
    let prompt: String
    func body(content: Content) -> some View {
        if show {
            content.searchable(text: $text, prompt: prompt)
        } else {
            content
        }
    }
}
