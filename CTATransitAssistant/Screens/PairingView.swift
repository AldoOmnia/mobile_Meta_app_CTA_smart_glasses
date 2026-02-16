//
//  PairingView.swift
//  CTA Transit Assistant
//
//  Screen 1: Connect to Meta AI Glasses via Meta DAT
//

import SwiftUI

struct PairingView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            
            Image(systemName: "glasses")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
            
            Text("Connect Your Glasses")
                .font(.title.bold())
            
            Text("Pair with Meta AI Glasses to hear train arrivals hands-free.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            switch appState.metaDATService.pairingState {
            case .idle, .failed:
                Button(action: { appState.metaDATService.startPairing() }) {
                    Label("Pair Glasses", systemImage: "link")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
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
            }
            
            Spacer()
        }
        .padding()
        .onChange(of: appState.metaDATService.isPaired) { _, paired in
            if paired { appState.isGlassesPaired = true }
        }
    }
}
