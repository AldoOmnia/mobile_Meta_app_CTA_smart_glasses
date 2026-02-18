//
//  GlassesActivatorView.swift
//  CTA Transit Assistant
//
//  Main activator: use everything via glasses with step-by-step AI audio (accessibility)
//

import SwiftUI

private let ctaBlue = Color(red: 0, green: 0.184, blue: 0.424)

struct GlassesActivatorView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("skipGlassesActivator") private var skipActivator = false
    @State private var isSpeaking = false
    
    var body: some View {
        Group {
            if skipActivator {
                MainTabView()
            } else {
                activatorContent
            }
        }
    }
    
    private var activatorContent: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Glasses icon
            glassesIcon
                .frame(width: 120, height: 120)
                .padding(.bottom, 24)
            
            Text("Use your glasses for everything")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            
            Text("Get step-by-step AI audio instructions for schedules, arrivals, and safety recording—hands-free.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
            
            Button {
                speakGlassesInstructions()
            } label: {
                HStack(spacing: 12) {
                    if isSpeaking {
                        ProgressView()
                            .tint(.white)
                    } else {
                        glassesButtonIcon
                    }
                    Text(isSpeaking ? "Speaking..." : "Start with Glasses")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            }
            .buttonStyle(.borderedProminent)
            .tint(ctaBlue)
            .disabled(isSpeaking)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            
            Button("Continue in app") {
                skipActivator = true
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(ctaBlue)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    @ViewBuilder
    private var glassesIcon: some View {
        if UIImage(named: "GlassesSilhouette") != nil {
            Image("GlassesSilhouette")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(ctaBlue)
        } else {
            Image(systemName: "glasses")
                .font(.system(size: 60))
                .foregroundStyle(ctaBlue)
        }
    }
    
    @ViewBuilder
    private var glassesButtonIcon: some View {
        if UIImage(named: "GlassesSilhouette") != nil {
            Image("GlassesSilhouette")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundColor(.white)
        } else {
            Image(systemName: "glasses")
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
    }
    
    private func speakGlassesInstructions() {
        isSpeaking = true
        let steps = Self.glassesInstructionSteps
        Task {
            for text in steps {
                appState.metaDATService.speakToGlasses(text)
                try? await Task.sleep(nanoseconds: 4_500_000_000)
            }
            await MainActor.run { isSpeaking = false }
        }
    }
    
    /// Short phrases (1–2 sentences max) for glasses audio—long text is hard to follow in-ear.
    static let glassesInstructionSteps: [String] = [
        "Welcome to CTA Transit Assistant. Use your glasses for everything.",
        "Schedules shows train arrivals. Tap a station or use your phone to pick.",
        "Follow This Train lists stops for a run number. Tap any stop to hear it.",
        "Safety Recording captures POV video from your glasses. Saves to your phone.",
        "Operator mode reads service alerts and schedules to your glasses.",
        "Tap any arrival or stop to hear it. Or use the app on your phone."
    ]
}

// MARK: - Glasses Guide Sheet (from Settings)

struct GlassesGuideSheet: View {
    @EnvironmentObject var appState: AppState
    let onDismiss: () -> Void
    @State private var isSpeaking = false
    private let sheetBlue = Color(red: 0, green: 0.184, blue: 0.424)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Get step-by-step AI audio instructions for everything in the app.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                Button {
                    speakInstructions()
                } label: {
                    HStack {
                        if isSpeaking {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "glasses")
                                .font(.title2)
                        }
                        Text(isSpeaking ? "Speaking..." : "Start with Glasses")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(sheetBlue)
                .disabled(isSpeaking)
                Spacer()
            }
            .navigationTitle("Glasses Audio Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDismiss() }
                }
            }
        }
    }
    
    private func speakInstructions() {
        isSpeaking = true
        let steps = GlassesActivatorView.glassesInstructionSteps
        Task {
            for text in steps {
                appState.metaDATService.speakToGlasses(text)
                try? await Task.sleep(nanoseconds: 4_500_000_000)
            }
            await MainActor.run { isSpeaking = false }
        }
    }
}
