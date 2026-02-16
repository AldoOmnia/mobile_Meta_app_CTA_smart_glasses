//
//  FollowTrainView.swift
//  CTA Transit Assistant
//
//  Screen 4: (Optional) In-train mode; upcoming stops
//

import SwiftUI

struct FollowTrainView: View {
    @EnvironmentObject var appState: AppState
    @State private var runNumber = ""
    @State private var stops: [CTAFollowStop] = []
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter the run number shown on your train")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                TextField("Run number", text: $runNumber)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                
                Button("Get Stops") {
                    Task { await fetchStops() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(runNumber.isEmpty || isLoading)
                
                if let err = error {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                if isLoading {
                    ProgressView()
                }
                
                if !stops.isEmpty {
                    List(stops) { stop in
                        HStack {
                            Text(stop.stopName)
                            Spacer()
                            Button {
                                appState.metaDATService.speakToGlasses(stop.spokenSummary)
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Follow This Train")
        }
    }
    
    private func fetchStops() async {
        isLoading = true
        error = nil
        do {
            stops = try await appState.ctaService.fetchFollowThisTrain(runNumber: runNumber)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
