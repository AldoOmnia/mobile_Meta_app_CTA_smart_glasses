//
//  UserProfile.swift
//  CTA Transit Assistant
//

import SwiftUI

struct UserProfile: Codable {
    var displayName: String
    var profileImageData: Data?
    var preferredStationId: String?
    var recordingEnabled: Bool
    var locationSharingEnabled: Bool
    
    static let `default` = UserProfile(
        displayName: "Rider",
        profileImageData: nil,
        preferredStationId: nil,
        recordingEnabled: false,
        locationSharingEnabled: false
    )
}
