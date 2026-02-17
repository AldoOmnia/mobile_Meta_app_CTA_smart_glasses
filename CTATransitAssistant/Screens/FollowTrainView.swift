//
//  FollowTrainView.swift
//  CTA Transit Assistant
//
//  In-train mode: upcoming stops. Pre-selected examples + run number entry.
//

import SwiftUI

private let ctaBlue = Color(red: 0, green: 0.184, blue: 0.424)

/// Example run numbers by line (for demo; actual runs vary)
private let presets: [(line: String, runs: [String])] = [
    ("Red Line", ["901", "902", "905", "908"]),
    ("Blue Line", ["101", "102", "105", "108"]),
    ("Brown Line", ["301", "302", "305"]),
    ("Green Line", ["501", "502", "505"]),
    ("Orange Line", ["201", "202", "205"]),
    ("Purple Line", ["401", "402", "405"]),
]

struct FollowTrainView: View {
    @EnvironmentObject var appState: AppState
    @State private var runNumber = ""
    @State private var stops: [CTAFollowStop] = []
    @State private var isLoading = false
    @State private var error: String?
    @AppStorage("RecentRunNumbers") private var recentRunsData: Data?
    
    private var recentRuns: [String] {
        (try? JSONDecoder().decode([String].self, from: recentRunsData ?? Data())) ?? []
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Enter the run number shown on your train, or pick a preset:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // Presets by line
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Select by Line")
                            .font(.headline)
                        ForEach(presets, id: \.line) { preset in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(preset.line)
                                    .font(.subheadline.weight(.medium))
                                FlowLayout(spacing: 8) {
                                    ForEach(preset.runs, id: \.self) { run in
                                        PresetButton(run: run) {
                                            runNumber = run
                                            Task { await fetchStops() }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Recent
                    if !recentRuns.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent")
                                .font(.headline)
                            FlowLayout(spacing: 8) {
                                ForEach(recentRuns, id: \.self) { run in
                                    PresetButton(run: run) {
                                        runNumber = run
                                        Task { await fetchStops() }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Manual entry
                    HStack {
                        TextField("Run number", text: $runNumber)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        Button("Get Stops") {
                            Task { await fetchStops() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(ctaBlue)
                        .disabled(runNumber.isEmpty || isLoading)
                    }
                    
                    if let err = error {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                    
                    if !stops.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Upcoming Stops")
                                .font(.headline)
                            ForEach(stops) { stop in
                                HStack {
                                    Text(stop.stopName)
                                    Spacer()
                                    Button {
                                        appState.metaDATService.speakToGlasses(stop.spokenSummary)
                                    } label: {
                                        Image(systemName: "speaker.wave.2.fill")
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Follow This Train")
        }
    }
    
    private func fetchStops() async {
        guard !runNumber.isEmpty else { return }
        isLoading = true
        error = nil
        do {
            stops = try await appState.ctaService.fetchFollowThisTrain(runNumber: runNumber)
            addToRecent(runNumber)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    private func addToRecent(_ run: String) {
        var recent = recentRuns
        recent.removeAll { $0 == run }
        recent.insert(run, at: 0)
        recentRunsData = try? JSONEncoder().encode(Array(recent.prefix(5)))
    }
}

struct PresetButton: View {
    let run: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(run)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (i, pos) in result.positions.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let width = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        
        return (CGSize(width: width, height: y + rowHeight), positions)
    }
}
