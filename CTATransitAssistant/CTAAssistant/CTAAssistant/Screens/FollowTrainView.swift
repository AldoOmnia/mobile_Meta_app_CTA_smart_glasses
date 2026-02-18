//
//  FollowTrainView.swift
//  CTA Transit Assistant
//
//  In-train mode: upcoming 'L' stops. Pre-selected line presets + run number entry.
//  Bus arrivals at a stop (CTA Bus Tracker API).
//

import SwiftUI

private let ctaBlue = Color(red: 0, green: 0.184, blue: 0.424)

/// Example run number formats by line—real run numbers change throughout the day. User must enter the number shown on their train.
private let presets: [(line: String, runs: [String])] = [
    ("Red", ["901", "902", "905"]),
    ("Blue", ["101", "102", "105"]),
    ("Brown", ["301", "302"]),
    ("Green", ["501", "502"]),
    ("Orange", ["201", "202"]),
    ("Purple", ["401", "402"]),
]

struct FollowTrainView: View {
    @EnvironmentObject var appState: AppState
    @State private var runNumber = ""
    @State private var stops: [CTAFollowStop] = []
    @State private var lastFetchedRun: String?
    @State private var isLoading = false
    @State private var error: String?
    @State private var showStopsOverlay = true
    @AppStorage("RecentRunNumbers") private var recentRunsData: Data?
    
    // Live runs from arrivals API
    @State private var activeRuns: [(run: String, route: String)] = []
    @State private var loadingActiveRuns = false
    
    // Bus tracking
    @State private var busStopId = ""
    @State private var busArrivals: [CTABusArrival] = []
    @State private var busLoading = false
    @State private var busError: String?
    
    private var recentRuns: [String] {
        (try? JSONDecoder().decode([String].self, from: recentRunsData ?? Data())) ?? []
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 0) {
                        routeStatusSection
                        followTrainSection
                        busArrivalsSection
                    }
                }
                
                if !stops.isEmpty, let run = lastFetchedRun {
                    if showStopsOverlay {
                        stopsOverlayCard(run: run)
                    } else {
                        Button {
                            showStopsOverlay = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "train.side.front.car")
                                    .foregroundColor(ctaBlue)
                                Text("Run \(run) — \(stops.count) stops loaded. Tap to show")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Follow Train")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadActiveRunNumbers() }
        }
    }
    
    // MARK: - L Route Status (matches Schedules)
    private var routeStatusSection: some View {
        RouteStatusSection()
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 16)
    }
    
    // MARK: - Follow This Train
    private var followTrainSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "train.side.front.car")
                    .font(.title3)
                    .foregroundColor(CTAColors.blueLineBlue)
                Text("Follow this train")
                    .font(.headline)
                    .foregroundColor(CTAColors.blueLineBlue)
            }
            .padding(.horizontal)
            
            Text("Tap a live run below (from trains in service now), or enter a run number from your train's display.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            // Live runs (from arrivals API)
            if loadingActiveRuns {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.9)
                    Text("Loading live runs...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            } else if !activeRuns.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Live runs right now")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    FlowLayout(spacing: 8) {
                        ForEach(activeRuns, id: \.run) { item in
                            Button {
                                runNumber = item.run
                                Task { await fetchStops() }
                            } label: {
                                HStack(spacing: 6) {
                                    CTALineBadge(item.route, compact: true)
                                    Text(item.run)
                                        .font(.subheadline.weight(.medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(ctaLineColor(item.route).opacity(0.2))
                                .foregroundColor(ctaLineColor(item.route))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            // Presets by line (fallback format examples)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(presets, id: \.line) { preset in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            CTALineBadge(preset.line, compact: true)
                            Text("Line")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                        }
                        FlowLayout(spacing: 8) {
                            ForEach(preset.runs, id: \.self) { run in
                                PresetButton(run: run) {
                                    runNumber = run
                                    Task { await fetchStops() }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            // Recent
            if !recentRuns.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent runs")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    FlowLayout(spacing: 8) {
                        ForEach(recentRuns, id: \.self) { run in
                            PresetButton(run: run) {
                                runNumber = run
                                Task { await fetchStops() }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Manual entry
            HStack(spacing: 12) {
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
            .padding(.horizontal)
            
            if let err = error {
                Text(err)
                    .font(.caption)
                    .foregroundColor(CTAColors.redLineRed)
                    .padding(.horizontal)
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            
            if !stops.isEmpty {
                Text("Tap a stop below to hear it again on your glasses.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
        .padding(.bottom, 24)
    }
    
    private func stopsOverlayCard(run: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Run \(run) — Upcoming stops")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(CTAColors.greenLineGreen)
                        Text("Sent to glasses")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button {
                    showStopsOverlay = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                                .frame(width: 20, alignment: .center)
                            Text(stop.stopName)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Button {
                                appState.metaDATService.speakToGlasses(stop.spokenSummary)
                            } label: {
                                glassesSpeakIcon
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(index % 2 == 0 ? Color.clear : Color(.tertiarySystemBackground).opacity(0.5))
                    }
                }
            }
            .frame(maxHeight: 220)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Bus Arrivals
    private var busArrivalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "bus.fill")
                    .font(.title3)
                    .foregroundColor(CTAColors.blueLineBlue)
                Text("Bus arrivals")
                    .font(.headline)
                    .foregroundColor(CTAColors.blueLineBlue)
            }
            .padding(.horizontal)
            
            Text("Check when the next bus arrives at a stop. Enter the stop ID (e.g. 14795 for Michigan & Lake):")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                TextField("Stop ID", text: $busStopId)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                Button("Get Arrivals") {
                    Task { await fetchBusArrivals() }
                }
                .buttonStyle(.borderedProminent)
                .tint(ctaBlue)
                .disabled(busStopId.isEmpty || busLoading)
            }
            .padding(.horizontal)
            
            if let err = busError {
                Text(err)
                    .font(.caption)
                    .foregroundColor(CTAColors.redLineRed)
                    .padding(.horizontal)
            }
            
            if busLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            
            if !busArrivals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next buses")
                        .font(.headline)
                        .padding(.horizontal)
                    ForEach(busArrivals.prefix(6)) { arrival in
                        HStack(spacing: 12) {
                            Text("Route \(arrival.route)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(ctaBlue)
                            Text("to \(arrival.destination)")
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            Text("\(arrival.predictionMinutes) min")
                                .font(.subheadline.weight(.medium))
                            Button {
                                appState.metaDATService.speakToGlasses(arrival.spokenSummary)
                            } label: {
                                glassesSpeakIcon
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 8)
            }
        }
        .padding(.bottom, 32)
    }
    
    @ViewBuilder
    private var glassesSpeakIcon: some View {
        if UIImage(named: "GlassesIcon") != nil {
            Image("GlassesIcon")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundStyle(ctaBlue)
        } else {
            Image(systemName: "speaker.wave.2.fill")
                .foregroundStyle(ctaBlue)
        }
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
    
    private func fetchStops() async {
        guard !runNumber.isEmpty else { return }
        isLoading = true
        error = nil
        stops = []
        do {
            stops = try await appState.ctaService.fetchFollowThisTrain(runNumber: runNumber)
            lastFetchedRun = runNumber
            showStopsOverlay = true
            addToRecent(runNumber)
            if !stops.isEmpty {
                speakStopsToGlassesInChunks(stops)
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    /// Speak stops in chunks of 2 (1–2 sentences max) so glasses audio stays brief.
    private func speakStopsToGlassesInChunks(_ stopList: [CTAFollowStop]) {
        let summaries = stopList.map { $0.spokenSummary }
        let chunkSize = 2
        Task {
            for i in stride(from: 0, to: summaries.count, by: chunkSize) {
                let chunk = Array(summaries[i..<min(i + chunkSize, summaries.count)])
                appState.metaDATService.speakToGlasses(chunk.joined(separator: ". "))
                try? await Task.sleep(nanoseconds: 3_500_000_000)  // 3.5s between chunks
            }
        }
    }
    
    private func addToRecent(_ run: String) {
        var recent = recentRuns
        recent.removeAll { $0 == run }
        recent.insert(run, at: 0)
        recentRunsData = try? JSONEncoder().encode(Array(recent.prefix(5)))
    }
    
    private func fetchBusArrivals() async {
        guard !busStopId.isEmpty else { return }
        busLoading = true
        busError = nil
        busArrivals = []
        do {
            busArrivals = try await appState.busService.fetchPredictions(stopId: busStopId)
        } catch {
            busError = error.localizedDescription
        }
        busLoading = false
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
