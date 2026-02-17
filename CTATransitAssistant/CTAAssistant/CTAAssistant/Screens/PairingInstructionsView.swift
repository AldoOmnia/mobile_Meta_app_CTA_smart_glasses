//
//  PairingInstructionsView.swift
//  CTA Transit Assistant
//
//  Meta DAT pairing instructions per Meta Wearables Developer docs.
//  Ref: wearables.developer.meta.com/docs/develop/
//  Ref: github.com/facebook/meta-wearables-dat-ios (CameraAccess sample)
//

import SwiftUI

private let ctaBlue = Color(red: 0, green: 0.184, blue: 0.424)

private let metaAIAppStoreURL = "https://apps.apple.com/app/meta-ai/id1558240027"
private let metaAIScheme = "metaai://"

struct PairingInstructionsView: View {
    let onStartPairing: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Before you pair, follow these steps:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Step 1: Developer Mode - with Open Meta AI button
                    VStack(alignment: .leading, spacing: 8) {
                        instructionRow(
                            number: 1,
                            title: "Enable Developer Mode",
                            detail: "Open the Meta AI app. Go to Settings → Developer Mode and turn it ON."
                        )
                        Button(action: openMetaAIApp) {
                            Label("Open Meta AI App", systemImage: "arrow.up.forward.square")
                                .font(.subheadline)
                                .foregroundColor(ctaBlue)
                        }
                    }
                    
                    instructionRow(
                        number: 2,
                        title: "Charge your glasses",
                        detail: "Ensure your Ray-Ban Meta or Oakley Meta glasses are charged."
                    )
                    
                    // Step 3: Bluetooth - iOS only allows opening our app's settings, not Bluetooth directly
                    VStack(alignment: .leading, spacing: 8) {
                        instructionRow(
                            number: 3,
                            title: "Turn on Bluetooth",
                            detail: "Go to iPhone Settings → Bluetooth and turn it ON. Keep your phone and glasses close together."
                        )
                        Button(action: openBluetoothSettings) {
                            Label("Open Bluetooth Settings", systemImage: "antenna.radiowaves.left.and.right")
                                .font(.subheadline)
                                .foregroundColor(ctaBlue)
                        }
                    }
                    
                    instructionRow(
                        number: 4,
                        title: "Wear your glasses",
                        detail: "Put on your glasses. The app will discover and connect when you tap Connect below."
                    )
                    
                    VStack(spacing: 12) {
                        Text("Supported devices: Ray-Ban Meta, Oakley Meta HSTN")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Link("Meta Wearables Developer Docs", destination: URL(string: "https://wearables.developer.meta.com/docs/develop/")!)
                            .font(.caption)
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .navigationTitle("How to Pair")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button(action: onStartPairing) {
                        Label("Connect to Glasses", systemImage: "link")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ctaBlue)
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
    }
    
    private func openMetaAIApp() {
        // Try Meta AI app URL scheme first; fall back to App Store
        if let metaURL = URL(string: metaAIScheme),
           UIApplication.shared.canOpenURL(metaURL) {
            UIApplication.shared.open(metaURL)
        } else if let storeURL = URL(string: metaAIAppStoreURL) {
            UIApplication.shared.open(storeURL)
        }
    }
    
    private func openBluetoothSettings() {
        // Try Bluetooth URL first (device-dependent; may not work on all iOS versions).
        // Fallback to our app's settings if it fails.
        if let url = URL(string: "App-Prefs:Bluetooth") {
            UIApplication.shared.open(url) { success in
                if !success {
                    openSettings()
                }
            }
        } else {
            openSettings()
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func instructionRow(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(ctaBlue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
