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
    @State private var showPairingInstructions = false
    
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // CTA Logo at top (or SF Symbol fallback)
                logoSection
                    .padding(.top, 20)
                
                Spacer(minLength: 24)
                
                Text("Pair with Meta AI Glasses to hear train arrivals hands-free")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                
                // Glasses in CTA blue with pulse
                glassesSection
                    .padding(.vertical, 16)
                
                Spacer(minLength: 24)
                
                // Buttons
                buttonsSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                
                // Powered by Omnia
                poweredBySection
                    .padding(.bottom, 20)
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            startPulseAnimation()
        }
        .onChange(of: appState.metaDATService.isPaired) { _, paired in
            if paired { appState.isGlassesPaired = true }
        }
        .sheet(isPresented: $showPairingInstructions) {
            PairingInstructionsView(
                onStartPairing: {
                    showPairingInstructions = false
                    appState.metaDATService.startPairing()
                },
                onDismiss: { showPairingInstructions = false }
            )
        }
    }
    
    @ViewBuilder
    private var logoSection: some View {
        if UIImage(named: "CTALogo") != nil {
            Image("CTALogo")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
        } else {
            Image(systemName: "train.side.front.car")
                .font(.system(size: 40))
                .foregroundStyle(ctaBlue)
        }
    }
    
    @ViewBuilder
    private var glassesSection: some View {
        if UIImage(named: "GlassesSilhouette") != nil {
            ZStack {
                Image("GlassesSilhouette")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .foregroundColor(ctaBlue.opacity(pulseOpacity * 0.3))
                    .scaleEffect(pulseScale)
                
                Image("GlassesSilhouette")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(ctaBlue)
            }
        } else {
            Image(systemName: "glasses")
                .font(.system(size: 80))
                .foregroundStyle(ctaBlue)
        }
    }
    
    private var buttonsSection: some View {
        VStack(spacing: 16) {
            switch appState.metaDATService.pairingState {
            case .idle, .failed:
                Button(action: { showPairingInstructions = true }) {
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
                        .foregroundColor(.red)
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
            
            Button(action: {
                appState.isGlassesPaired = true
                appState.metaDATService.isPaired = true
                appState.metaDATService.pairingState = .connected
            }) {
                Text(isSimulator ? "Continue for Demo (Simulator)" : "Continue without Glasses")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
    }
    
    @ViewBuilder
    private var poweredBySection: some View {
        VStack(spacing: 8) {
            if UIImage(named: "OmniaLogo") != nil {
                Image("OmniaLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .opacity(0.8)
            }
            Text("Powered by Omnia")
                .font(.caption2)
                .foregroundColor(.secondary)
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

