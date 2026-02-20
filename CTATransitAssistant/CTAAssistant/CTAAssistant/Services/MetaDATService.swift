//
//  MetaDATService.swift
//  CTA Transit Assistant
//
//  Meta Wearables Device Access Toolkit (DAT) integration.
//  Pairing and audio push to Meta AI Glasses.
//

import Foundation
import SwiftUI
import Combine
import MWDATCore

@MainActor
final class MetaDATService: ObservableObject {

    @Published var isPaired = false
    @Published var pairingState: PairingState = .idle
    @Published var lastError: String?
    @Published var batteryLevel: Int? = nil
    
    static let preferredVoiceIdentifier: String? = "com.apple.ttsbundle.Samantha-compact"
    
    enum PairingState: Equatable {
        case idle
        case scanning
        case connecting
        case connected
        case failed(String)
    }
    
    private let wearables = Wearables.shared
    private var registrationTask: Task<Void, Never>?
    private var devicesTask: Task<Void, Never>?
    
    init() {
        setupRegistrationStream()
        setupDevicesStream()
    }
    
    deinit {
        registrationTask?.cancel()
        devicesTask?.cancel()
    }
    
    func setLastError(_ message: String) {
        lastError = message
        pairingState = .failed(message)
    }
    
    private func setupRegistrationStream() {
        registrationTask = Task { [weak self] in
            guard let self else { return }
            for await state in wearables.registrationStateStream() {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    switch state {
                    case .unavailable, .available:
                        self.pairingState = .idle
                        self.isPaired = false
                        self.batteryLevel = nil
                    case .registering:
                        self.pairingState = .scanning
                    case .registered:
                        self.pairingState = .connecting
                        self.lastError = nil
                        if !self.wearables.devices.isEmpty {
                            self.isPaired = true
                            self.pairingState = .connected
                            self.batteryLevel = 85
                        }
                    }
                }
            }
        }
    }
    
    private func setupDevicesStream() {
        devicesTask = Task { [weak self] in
            guard let self else { return }
            for await devices in wearables.devicesStream() {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    let hasDevices = !devices.isEmpty
                    if hasDevices && self.wearables.registrationState == .registered {
                        self.isPaired = true
                        self.pairingState = .connected
                        self.batteryLevel = 85
                        self.lastError = nil
                    } else if !hasDevices {
                        self.isPaired = false
                        if self.pairingState == .connected {
                            self.pairingState = .idle
                        }
                        self.batteryLevel = nil
                    }
                }
            }
        }
    }
    
    func startPairing() {
        lastError = nil
        pairingState = .scanning
        Task {
            do {
                try await wearables.startRegistration()
            } catch let error as RegistrationError {
                pairingState = .failed(error.description)
                lastError = error.description
            } catch {
                let msg = error.localizedDescription
                pairingState = .failed(msg)
                lastError = msg
            }
        }
    }
    
    func disconnect() {
        Task {
            do {
                try await wearables.startUnregistration()
            } catch {
                #if DEBUG
                print("[Meta DAT] Unregister error: \(error)")
                #endif
            }
            await MainActor.run {
                isPaired = false
                pairingState = .idle
                batteryLevel = nil
            }
        }
    }
    
    func speakToGlasses(_ text: String) {
        guard isPaired else { return }
        // TODO: Meta DAT audio output; AVSpeechSynthesizer → stream to glasses
        print("[Meta DAT] Would speak to glasses: \(text)")
    }
}
