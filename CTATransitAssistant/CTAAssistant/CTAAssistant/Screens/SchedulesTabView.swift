//
//  SchedulesTabView.swift
//  CTA Transit Assistant
//
//  Main tab: Schedules (Arrivals + Departures), recorder trigger, user profile.
//

import SwiftUI

private let ctaBlue = Color(red: 0, green: 0.184, blue: 0.424)

struct SchedulesTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var recordingService = SessionRecordingService()
    @AppStorage("UserProfile") private var userProfileData: Data?
    @State private var showRecordingGrant = false
    @State private var showProfileSettings = false
    
    private var userProfile: UserProfile {
        (try? JSONDecoder().decode(UserProfile.self, from: userProfileData ?? Data())) ?? .default
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Recorder trigger (top) - user-granted
                    recorderSection
                    
                    // User profile: location, picture, preferences
                    userProfileSection
                    
                    // Arrivals & Departures content
                    if appState.selectedStation != nil {
                        SchedulesContentView()
                    } else {
                        StationSelectView()
                    }
                }
            }
            .navigationTitle("Schedules")
            .toolbar {
                if appState.selectedStation != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Change Station") {
                            appState.selectedStation = nil
                        }
                    }
                }
            }
            .sheet(isPresented: $showRecordingGrant) {
                RecordingGrantSheet(
                    onGrant: {
                        recordingService.requestGrant()
                        showRecordingGrant = false
                    },
                    onDismiss: { showRecordingGrant = false }
                )
            }
            .sheet(isPresented: $showProfileSettings) {
                ProfileSettingsSheet(
                    profile: userProfile,
                    locationService: appState.locationService,
                    onSave: { updated in
                        saveProfile(updated)
                        showProfileSettings = false
                    },
                    onCancel: { showProfileSettings = false }
                )
            }
        }
    }
    
    private var recorderSection: some View {
        Group {
            if recordingService.hasUserGranted {
                Button(action: { recordingService.toggleRecording() }) {
                    HStack {
                        Image(systemName: recordingService.isRecording ? "stop.circle.fill" : "record.circle")
                            .font(.title2)
                            .foregroundColor(recordingService.isRecording ? .red : ctaBlue)
                        Text(recordingService.isRecording ? "Stop Recording" : "Start Safety Recording")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
            } else {
                Button(action: { showRecordingGrant = true }) {
                    HStack {
                        Image(systemName: "record.circle")
                            .font(.title2)
                            .foregroundColor(ctaBlue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Safety Recording")
                                .font(.subheadline.weight(.medium))
                            Text("Tap to enable session-based recording")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
        }
    }
    
    private var userProfileSection: some View {
        Button(action: { showProfileSettings = true }) {
            HStack(spacing: 12) {
                profileImage
                VStack(alignment: .leading, spacing: 6) {
                    Text(userProfile.displayName)
                        .font(.headline)
                    if appState.locationService.authorizationStatus == .authorizedWhenInUse,
                       let nearest = appState.locationService.nearestStation {
                        Label(nearest.stationName, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Location: Enable in Settings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    // Safety Recording status in profile
                    HStack(spacing: 4) {
                        Image(systemName: recordingService.hasUserGranted ? "record.circle.fill" : "record.circle")
                            .font(.caption2)
                            .foregroundColor(recordingService.hasUserGranted ? ctaBlue : .secondary)
                        Text(recordingService.hasUserGranted ? "Safety Recording enabled" : "Safety Recording: Tap above to enable")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    private var profileImage: some View {
        if let data = userProfile.profileImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(ctaBlue.opacity(0.6))
        }
    }
    
    private func saveProfile(_ profile: UserProfile) {
        userProfileData = try? JSONEncoder().encode(profile)
    }
}

// MARK: - Recording Grant Sheet

struct RecordingGrantSheet: View {
    let onGrant: () -> Void
    let onDismiss: () -> Void
    private let ctaBlue = Color(red: 0, green: 0.184, blue: 0.424)
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Safety Recording helps document transit incidents. Recordings are session-based (up to 2 min), stored efficiently, and only when you tap to start.")
                    .font(.body)
                
                Text("• Hands-free trigger at top of Schedules\n• Power-efficient, compressed storage\n• You control when recording starts and stops")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Enable Safety Recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enable") { onGrant() }
                        .fontWeight(.semibold)
                        .foregroundColor(ctaBlue)
                }
            }
        }
    }
}

// MARK: - Profile Settings Sheet

struct ProfileSettingsSheet: View {
    let profile: UserProfile
    let locationService: LocationService
    let onSave: (UserProfile) -> Void
    let onCancel: () -> Void
    @State private var displayName: String
    @State private var locationEnabled: Bool
    @State private var profileImageData: Data?
    @State private var showImagePicker = false
    private let ctaBlue = Color(red: 0, green: 0.184, blue: 0.424)
    
    init(profile: UserProfile, locationService: LocationService, onSave: @escaping (UserProfile) -> Void, onCancel: @escaping () -> Void) {
        self.profile = profile
        self.locationService = locationService
        self.onSave = onSave
        self.onCancel = onCancel
        _displayName = State(initialValue: profile.displayName)
        _locationEnabled = State(initialValue: profile.locationSharingEnabled)
        _profileImageData = State(initialValue: profile.profileImageData)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    HStack {
                        profileImageButton
                        TextField("Display Name", text: $displayName)
                    }
                }
                Section("Preferences") {
                    Toggle("Share Location for Nearest Station", isOn: $locationEnabled)
                        .onChange(of: locationEnabled) { enabled in
                            if enabled {
                                locationService.requestAuthorization()
                                locationService.startUpdatingLocation()
                            } else {
                                locationService.stopUpdatingLocation()
                            }
                        }
                }
            }
            .navigationTitle("Profile & Preferences")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = profile
                        updated.displayName = displayName
                        updated.locationSharingEnabled = locationEnabled
                        updated.profileImageData = profileImageData
                        onSave(updated)
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(ctaBlue)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(imageData: $profileImageData)
            }
        }
    }
    
    @ViewBuilder
    private var profileImageButton: some View {
        Button {
            showImagePicker = true
        } label: {
            if let data = profileImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(ctaBlue.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Image Picker (iOS 15 compatible)

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let edited = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage,
               let data = edited.jpegData(compressionQuality: 0.8) {
                parent.imageData = data
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
