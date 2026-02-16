//
//  PairingView.swift
//  CTA Transit Assistant
//
//  Screen 1: Connect to Meta AI Glasses via Meta DAT
//

import SwiftUI

// CTA brand blue - matches Chicago Transit Authority logo
private let ctaBlue = Color(red: 0, green: 0.184, blue: 0.424)

struct PairingView: View {
    @EnvironmentObject var appState: AppState
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.7
    
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // CTA Logo at top
            Image("CTALogo")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .padding(.top, 20)
            
            Spacer()
            
            // Main content
            VStack(spacing: 24) {
                Text("Pair with Meta AI Glasses to hear train arrivals hands-free")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 24)
                
                // Glasses silhouette in CTA blue with dynamic pulse
                ZStack {
                    // Outer pulse - "pairing mode coming soon"
                    Image("GlassesSilhouette")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .renderingMode(.template)
                        .foregroundStyle(ctaBlue.opacity(pulseOpacity * 0.3))
                        .scaleEffect(pulseScale)
                    
                    // Main glasses
                    Image("GlassesSilhouette")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .renderingMode(.template)
                        .foregroundStyle(ctaBlue)
                }
                .padding(.vertical, 16)
            }
            
            // Bypass for testing without glasses (simulator or device)
            Button(action: {
                appState.isGlassesPaired = true
                appState.metaDATService.isPaired = true
                appState.metaDATService.pairingState = .connected
            }) {
                Text(isSimulator ? "Continue for Demo" : "Continue without Glasses")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                switch appState.metaDATService.pairingState {
                case .idle, .failed:
                    Button(action: { appState.metaDATService.startPairing() }) {
                        Label("Pair Glasses", systemImage: "link")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ctaBlue)
                    .disabled(appState.metaDATService.pairingState == .scanning)
                    
                    if case .failed(let msg) = appState.metaDATService.pairingState {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                case .scanning, .connecting:
                    ProgressView("Searching for glasses...")
                        .padding()
                case .connected:
                    Button(action: {
                        appState.isGlassesPaired = true
                        appState.metaDATService.isPaired = true
                    }) {
                        Label("Continue", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ctaBlue)
                }
                
                // Simulator bypass - always show in simulator, or as secondary option
                if isSimulator {
                    Button(action: {
                        appState.isGlassesPaired = true
                        appState.metaDATService.isPaired = true
                        appState.metaDATService.pairingState = .connected
                    }) {
                        Text("Continue for Demo (Simulator)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            
            // Powered by Omnia
            VStack(spacing: 8) {
                Image("OmniaLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .opacity(0.8)
                Text("Powered by Omnia")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .onAppear {
            startPulseAnimation()
        }
        .onChange(of: appState.metaDATService.isPaired) { _, paired in
            if paired { appState.isGlassesPaired = true }
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.2
            pulseOpacity = 1.0
        }
    }
}
