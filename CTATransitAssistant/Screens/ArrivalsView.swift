//
//  ArrivalsView.swift
//  CTA Transit Assistant
//
//  Screen 3: Live arrival predictions; push to glasses
//

import SwiftUI

struct ArrivalsView: View {
    @EnvironmentObject var appState: AppState
    @State private var isLoading = false
    @State private var error: String?
    @State private var refreshTask: Task<Void, Never>?
    
    var body: some View {
        Group {
            if let station = appState.selectedStation {
                arrivalsContent(for: station)
            } else {
                stationPickerPrompt
            }
        }
        .navigationTitle("Arrivals")
        .refreshable {
            await refreshArrivals()
        }
    }
    
    private var stationPickerPrompt: some View {
        ContentUnavailableView(
            "Select a Station",
            systemImage: "mappin.circle",
            description: Text("Choose a station to see live arrival times")
        )
    }
    
    private func arrivalsContent(for station: CTAStation) -> some View {
        VStack(spacing: 0) {
            if let err = error {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }
            
            if isLoading {
                ProgressView()
                    .padding()
                Spacer()
            } else {
                List(appState.arrivals) { arrival in
                    HStack {
                        Image(systemName: routeIcon(arrival.route))
                            .foregroundStyle(routeColor(arrival.route))
                            .frame(width: 32)
                        VStack(alignment: .leading) {
                            Text("\(arrival.route) to \(arrival.destination)")
                                .font(.headline)
                            Text("\(arrival.predictionMinutes) min")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            appState.metaDATService.speakToGlasses(arrival.spokenSummary)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .task {
            await refreshArrivals()
        }
    }
    
    private func refreshArrivals() async {
        guard let station = appState.selectedStation else { return }
        isLoading = true
        error = nil
        do {
            let arrivals = try await appState.ctaService.fetchArrivals(mapId: station.mapId)
            appState.arrivals = arrivals
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    private func routeIcon(_ route: String) -> String {
        "train.side.front.car"
    }
    
    private func routeColor(_ route: String) -> Color {
        switch route.uppercased() {
        case "RED": return .red
        case "BLUE": return .blue
        case "GREEN": return .green
        case "BROWN": return .brown
        case "PURPLE": return .purple
        case "ORANGE": return .orange
        case "PINK": return .pink
        case "YELLOW": return .yellow
        default: return .primary
        }
    }
}
