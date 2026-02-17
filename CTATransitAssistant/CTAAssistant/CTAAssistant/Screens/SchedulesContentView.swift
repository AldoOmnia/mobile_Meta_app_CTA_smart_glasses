//
//  SchedulesContentView.swift
//  CTA Transit Assistant
//
//  Arrivals and Departures sections. CTA API provides arrivals; Departures = boarding soon.
//

import SwiftUI

struct SchedulesContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var isLoading = false
    @State private var error: String?
    
    /// Arrivals in 0–3 min = "Departing soon" (boarding)
    private var departingSoon: [CTAArrival] {
        appState.arrivals.filter { $0.predictionMinutes <= 3 }
    }
    
    /// Arrivals not yet departing (avoid duplicate listing)
    private var arrivals: [CTAArrival] {
        appState.arrivals.filter { $0.predictionMinutes > 3 }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let err = error {
                Text(err)
                    .font(.caption)
                    .foregroundColor(CTAColors.redLineRed)
                    .padding()
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                // Departures (boarding soon) - top priority
                if !departingSoon.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Departing Soon")
                                .font(.headline)
                                .padding(.horizontal)
                            ForEach(departingSoon) { arrival in
                                arrivalRow(arrival, highlight: true)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
                
                // All Arrivals (excludes departing soon)
                if !arrivals.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Arrivals")
                                .font(.headline)
                                .padding(.horizontal)
                            ForEach(arrivals) { arrival in
                                arrivalRow(arrival, highlight: false)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                } else if departingSoon.isEmpty && !isLoading {
                    Text("No arrivals right now. Pull to refresh.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                }
            }
        }
        .task {
            await refreshArrivals()
        }
        .refreshable {
            await refreshArrivals()
        }
    }
    
    private func arrivalRow(_ arrival: CTAArrival, highlight: Bool) -> some View {
        HStack(spacing: 12) {
            CTALineBadge(arrival.route, compact: true)
                .frame(minWidth: 58, alignment: .center)
                .fixedSize(horizontal: true, vertical: false)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(arrival.route) to \(arrival.destination)")
                    .font(highlight ? .headline : .subheadline.weight(.medium))
                    .lineLimit(1)
                Text("\(arrival.predictionMinutes) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                appState.metaDATService.speakToGlasses(arrival.spokenSummary)
            } label: {
                glassesSpeakIcon
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(highlight ? CTAColors.blueLineBlue.opacity(0.12) : Color.clear)
        .cornerRadius(10)
        .padding(.horizontal, 8)
    }
    
    private func refreshArrivals() async {
        guard let station = appState.selectedStation else { return }
        isLoading = true
        error = nil
        do {
            let result = try await appState.ctaService.fetchArrivals(mapId: station.mapId)
            appState.arrivals = result
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    @ViewBuilder
    private var glassesSpeakIcon: some View {
        if UIImage(named: "GlassesIcon") != nil {
            Image("GlassesIcon")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(CTAColors.blueLineBlue)
        } else {
            Image(systemName: "speaker.wave.2.fill")
                .foregroundStyle(CTAColors.blueLineBlue)
        }
    }
    
}
