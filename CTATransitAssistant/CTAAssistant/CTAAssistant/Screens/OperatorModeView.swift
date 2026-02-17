//
//  OperatorModeView.swift
//  CTA Transit Assistant
//
//  Operator: Pre-selected lines, service alerts, in-glasses notifications
//

import SwiftUI

private let ctaBlue = Color(red: 0, green: 0.184, blue: 0.424)

private var linePresets: [(name: String, color: Color, runs: [String])] {
    [
        ("Red", ctaLineColor("Red"), ["901", "902", "905", "908"]),
        ("Blue", ctaLineColor("Blue"), ["101", "102", "105", "108"]),
        ("Brown", ctaLineColor("Brown"), ["301", "302", "305"]),
        ("Green", ctaLineColor("Green"), ["501", "502", "505"]),
        ("Orange", ctaLineColor("Orange"), ["201", "202", "205"]),
        ("Purple", ctaLineColor("Purple"), ["401", "402", "405"]),
        ("Pink", ctaLineColor("Pink"), ["501", "502"]),
        ("Yellow", ctaLineColor("Yellow"), ["601", "602"]),
    ]
}

struct OperatorModeView: View {
    @EnvironmentObject var appState: AppState
    @State private var scheduleInfo: [String] = []
    @State private var loadingRun: String?
    @State private var error: String?
    @State private var activeRuns: [(run: String, route: String)] = []
    @State private var loadingActiveRuns = false
    @State private var serviceAlerts: [String] = [
        "Red Line: Minor delays between Roosevelt and 95th. Allow extra travel time.",
        "Blue Line: Normal service.",
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    serviceAlertsSection
                    preSelectedLinesSection
                }
                .padding()
            }
            .navigationTitle("Operator Mode")
            .task { await loadActiveRunNumbers() }
        }
    }
    
    private var serviceAlertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(CTAColors.orangeLineOrange)
                Text("Service Alerts")
                    .font(.headline)
            }
            ForEach(serviceAlerts, id: \.self) { alert in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(CTAColors.orangeLineOrange)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                    Text(alert)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
            Button {
                triggerAlertsInGlasses()
            } label: {
                HStack {
                    glassesSpeakIcon
                    Text("Send alerts to glasses")
                        .font(.subheadline.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(ctaBlue)
        }
    }
    
    private var preSelectedLinesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if loadingActiveRuns {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.9)
                    Text("Loading live runs...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else if !activeRuns.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Live runs — tap Fetch for schedule")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    FlowLayout(spacing: 8) {
                        ForEach(activeRuns, id: \.run) { item in
                            OperatorPresetButton(
                                run: item.run,
                                color: ctaLineColor(item.route),
                                isLoading: loadingRun == item.run,
                                onFetch: { Task { await fetchAndSpeak(run: item.run) } }
                            )
                        }
                    }
                }
            } else {
                Text("No live runs. Check back when trains are in service, or try line presets below.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("Line presets (example format)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(linePresets, id: \.name) { preset in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(preset.name + " Line")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(preset.color)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(preset.runs, id: \.self) { run in
                                OperatorPresetButton(
                                    run: run,
                                    color: preset.color,
                                    isLoading: loadingRun == run,
                                    onFetch: { Task { await fetchAndSpeak(run: run) } }
                                )
                            }
                        }
                    }
                }
            }
            
            if !scheduleInfo.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Schedule / Stops")
                        .font(.headline)
                    ForEach(scheduleInfo, id: \.self) { item in
                        Text(item)
                            .font(.subheadline)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(8)
                    }
                }
            }
            
            if let err = error {
                Text(err)
                    .font(.caption)
                    .foregroundColor(CTAColors.redLineRed)
            }
        }
    }
    
    @ViewBuilder
    private var glassesSpeakIcon: some View {
        if UIImage(named: "GlassesIcon") != nil {
            Image("GlassesIcon")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.white)
        } else {
            Image(systemName: "glasses")
                .font(.system(size: 18))
                .foregroundColor(.white)
        }
    }
    
    private func fetchAndSpeak(run: String) async {
        loadingRun = run
        error = nil
        scheduleInfo = []
        do {
            let stops = try await appState.ctaService.fetchFollowThisTrain(runNumber: run)
            scheduleInfo = stops.map { $0.spokenSummary }
            let text = scheduleInfo.isEmpty ? "No stops for run \(run)" : scheduleInfo.joined(separator: ". ")
            appState.metaDATService.speakToGlasses(text)
        } catch {
            self.error = error.localizedDescription
        }
        loadingRun = nil
    }
    
    private func loadActiveRunNumbers() async {
        loadingActiveRuns = true
        activeRuns = []
        do {
            activeRuns = try await appState.ctaService.fetchActiveRunNumbers()
        } catch {
            activeRuns = []
        }
        loadingActiveRuns = false
    }
    
    private func triggerAlertsInGlasses() {
        let text = serviceAlerts.joined(separator: ". ")
        appState.metaDATService.speakToGlasses(text)
    }
}

struct OperatorPresetButton: View {
    let run: String
    let color: Color
    let isLoading: Bool
    let onFetch: () -> Void
    
    var body: some View {
        Button(action: onFetch) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(run)
                        .font(.subheadline.weight(.medium))
                }
                Image(systemName: "arrow.down.circle")
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}
