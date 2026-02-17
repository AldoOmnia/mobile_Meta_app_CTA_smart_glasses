//
//  ServiceAlertsView.swift
//  CTA Transit Assistant
//
//  CTA design: Current alerts + Accessibility Alerts (alerts.png)
//

import SwiftUI
import CoreLocation

struct CTAServiceAlert: Identifiable {
    let id = UUID()
    let stationNames: [String]
    let lines: [String]
    let dateRange: String
    let title: String
    let statusType: AlertStatus
    let description: String
}

enum AlertStatus {
    case normalService
    case elevatorStatus
    case specialNote
    case emergency  // Medical, fire, etc. — may trigger auto POV recording when user is nearby
}

struct ServiceAlertsView: View {
    @State private var currentExpanded = true
    @State private var accessibilityExpanded = true
    @State private var alerts: [CTAServiceAlert] = SampleAlerts.items
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Service alerts")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.bottom, 16)
            
            alertSection(
                title: "Current alerts",
                count: alerts.filter { $0.statusType == .normalService || $0.statusType == .specialNote }.count,
                expanded: $currentExpanded,
                items: alerts.filter { $0.statusType != .elevatorStatus }
            )
            
            alertSection(
                title: "Accessibility Alerts",
                count: alerts.filter { $0.statusType == .elevatorStatus }.count,
                expanded: $accessibilityExpanded,
                items: alerts.filter { $0.statusType == .elevatorStatus }
            )
        }
    }
    
    private func alertSection(
        title: String,
        count: Int,
        expanded: Binding<Bool>,
        items: [CTAServiceAlert]
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation { expanded.wrappedValue.toggle() }
            } label: {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(count)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CTAColors.blueLineBlue)
                        .clipShape(Circle())
                    Image(systemName: expanded.wrappedValue ? "minus" : "plus")
                        .font(.caption.weight(.semibold))
                }
                .padding()
                .background(Color(.secondarySystemBackground))
            }
            .buttonStyle(.plain)
            
            if expanded.wrappedValue {
                ForEach(items) { alert in
                    alertRow(alert)
                }
            }
        }
    }
    
    private func alertRow(_ alert: CTAServiceAlert) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(alert.stationNames, id: \.self) { name in
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CTAColors.signGrey)
                        .cornerRadius(6)
                }
            }
            HStack(spacing: 6) {
                ForEach(alert.lines, id: \.self) { line in
                    CTALineBadge(line, compact: true)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            Text(alert.dateRange)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(alert.title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(CTAColors.blueLineBlue)
                .underline()
            HStack(spacing: 6) {
                statusIndicator(alert.statusType)
            }
            Text(alert.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func statusIndicator(_ status: AlertStatus) -> some View {
        switch status {
        case .normalService:
            CTANormalServiceIndicator()
        case .elevatorStatus:
            CTAAlertIndicator("Elevator Status")
        case .specialNote:
            CTAAlertIndicator("Special Note")
        case .emergency:
            CTAAlertIndicator("Emergency")
        }
    }
}

extension CTAServiceAlert {
    /// First station's coordinates for proximity check. Nil if no matching station.
    var alertCoordinate: CLLocationCoordinate2D? {
        guard let firstStation = stationNames.first,
              let station = CTAStationsRepository.shared.station(byName: firstStation) else { return nil }
        return station.coordinate
    }
    
    var isEmergency: Bool { statusType == .emergency }
}

enum SampleAlerts {
    static let items: [CTAServiceAlert] = [
        CTAServiceAlert(
            stationNames: [],
            lines: ["Red"],
            dateRange: "Mon, Jan 5 2026 to TBD",
            title: "State/Lake Elevated Station Temporary Closure",
            statusType: .normalService,
            description: "Effective now, the State/Lake Loop Elevated station is closed for reconstruction into 2029. Please use adjacent stations at Clark/Lake or Washington/Wabash."
        ),
        CTAServiceAlert(
            stationNames: ["Jackson"],
            lines: ["Red"],
            dateRange: "Thu, Jan 8 2026 - 12:22 PM to TBD",
            title: "Elevator at Jackson (Van Buren entrance) Temporarily Out-of-Service",
            statusType: .elevatorStatus,
            description: "The elevator to/from platform at the Jackson Van Buren entrance is temporarily out-of-service due to elevator upgrades."
        ),
        CTAServiceAlert(
            stationNames: ["Lawrence"],
            lines: ["Red"],
            dateRange: "Tue, Feb 17 2026 - 5:51 AM to TBD",
            title: "Elevator at Lawrence Temporarily Out-of-Service",
            statusType: .elevatorStatus,
            description: "The elevator to/from platform at Lawrence (Red Line) is temporarily out-of-service."
        ),
        CTAServiceAlert(
            stationNames: ["Howard"],
            lines: ["Red", "Purple", "Yellow"],
            dateRange: "Tue, Feb 17 2026 - 7:04 AM to TBD",
            title: "Elevator at Howard Temporarily Out-of-Service",
            statusType: .elevatorStatus,
            description: "The 95th- and Loop- bound platform elevator at Howard (Red, Purple, Yellow Lines) is temporarily out-of-service."
        ),
        CTAServiceAlert(
            stationNames: ["Roosevelt"],
            lines: ["Red", "Orange", "Green"],
            dateRange: "Tue, Feb 17 2026 - 2:30 PM to TBD",
            title: "Medical Emergency on Tracks — Trains Suspended",
            statusType: .emergency,
            description: "Service temporarily suspended at Roosevelt due to medical emergency on tracks. CTA and emergency personnel responding."
        ),
    ]
}
