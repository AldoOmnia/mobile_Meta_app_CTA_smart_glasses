//
//  SessionRecordingService.swift
//  CTA Transit Assistant
//
//  Session-based recording via Meta AI Glasses for transit safety.
//  User-granted, efficient storage/power. Triggered at top of main page.
//  Ref: Meta DAT camera APIs
//

import Foundation
import SwiftUI

@MainActor
final class SessionRecordingService: ObservableObject {
    @Published var isRecording = false
    @Published var hasUserGranted = false
    @Published var lastRecordingURL: URL?
    
    /// Max session duration (seconds) for power/storage efficiency
    private let maxSessionSeconds = 120
    
    init() {
        // Load user preference
        hasUserGranted = UserDefaults.standard.bool(forKey: "RecordingUserGranted")
    }
    
    func requestGrant() {
        hasUserGranted = true
        UserDefaults.standard.set(true, forKey: "RecordingUserGranted")
    }
    
    func revokeGrant() {
        hasUserGranted = false
        UserDefaults.standard.set(false, forKey: "RecordingUserGranted")
        if isRecording {
            stopRecording()
        }
    }
    
    func startRecording() {
        guard hasUserGranted else { return }
        // TODO: Meta DAT - start camera recording via glasses
        isRecording = true
    }
    
    func stopRecording() {
        // TODO: Meta DAT - stop and save recording
        isRecording = false
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
}
