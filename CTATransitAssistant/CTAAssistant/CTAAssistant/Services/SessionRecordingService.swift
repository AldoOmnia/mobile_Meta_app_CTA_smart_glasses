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
import Combine

@MainActor
final class SessionRecordingService: ObservableObject {
    @Published var isRecording = false
    @Published var hasUserGranted = false
    @Published var lastRecordingURL: URL?
    @Published var savedRecordings: [URL] = []
    
    private let maxSessionSeconds = 120
    private let recordingsKey = "SafetyRecordingURLs"
    
    init() {
        hasUserGranted = UserDefaults.standard.bool(forKey: "RecordingUserGranted")
        loadRecordings()
    }
    
    func requestGrant() {
        hasUserGranted = true
        UserDefaults.standard.set(true, forKey: "RecordingUserGranted")
    }
    
    func requestGrantAndStart() {
        requestGrant()
        startRecording()
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
        // TODO: Meta DAT - start camera recording via glasses; show live POV on phone
        isRecording = true
    }
    
    func stopRecording() {
        if isRecording {
            let url = savePlaceholderRecording()
            if let url = url {
                lastRecordingURL = url
                savedRecordings.insert(url, at: 0)
                saveRecordings()
            }
        }
        isRecording = false
    }
    
    private func savePlaceholderRecording() -> URL? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("SafetyRecordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let name = "recording_\(Date().timeIntervalSince1970).mp4"
        let url = dir.appendingPathComponent(name)
        try? Data().write(to: url)
        return url
    }
    
    private func loadRecordings() {
        if let urls = UserDefaults.standard.stringArray(forKey: recordingsKey)?
            .compactMap({ URL(string: $0) }) {
            savedRecordings = urls.filter { FileManager.default.fileExists(atPath: $0.path) }
        }
    }
    
    private func saveRecordings() {
        UserDefaults.standard.set(savedRecordings.map { $0.absoluteString }, forKey: recordingsKey)
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
}
