//
//  OperatorModeView.swift
//  CTA Transit Assistant
//
//  Screen 6: Line/run selection, schedule view
//

import SwiftUI

struct OperatorModeView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedLine = "Red"
    @State private var runNumber = ""
    @State private var scheduleInfo: [String] = []
    
    private let lines = ["Red", "Blue", "Brown", "Green", "Orange", "Pink", "Purple", "Yellow"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Line & Run") {
                    Picker("Line", selection: $selectedLine) {
                        ForEach(lines, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    
                    TextField("Run Number", text: $runNumber)
                        .keyboardType(.numberPad)
                }
                
                Section("Schedule / Delays") {
                    if scheduleInfo.isEmpty {
                        Text("Enter run number and fetch for schedule info.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(scheduleInfo, id: \.self) { item in
                            Text(item)
                        }
                    }
                }
                
                Button("Speak Schedule to Glasses") {
                    let text = scheduleInfo.isEmpty
                        ? "No schedule loaded for run \(runNumber)"
                        : scheduleInfo.joined(separator: ". ")
                    appState.metaDATService.speakToGlasses(text)
                }
                .disabled(scheduleInfo.isEmpty)
            }
            .navigationTitle("Operator Mode")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Fetch") {
                        Task { await fetchSchedule() }
                    }
                    .disabled(runNumber.isEmpty)
                }
            }
        }
    }
    
    private func fetchSchedule() async {
        guard !runNumber.isEmpty else { return }
        do {
            let stops = try await appState.ctaService.fetchFollowThisTrain(runNumber: runNumber)
            scheduleInfo = stops.map { $0.spokenSummary }
        } catch {
            scheduleInfo = ["Error: \(error.localizedDescription)"]
        }
    }
}
