//
//  CTADesignComponents.swift
//  CTA Transit Assistant
//
//  CTA transport design language: line badges, status indicators, route diagram
//

import SwiftUI

// MARK: - Line Colors (official CTA swatch - colors.png)
// RGB Decimal: 0–255 → SwiftUI 0–1

func ctaLineColor(_ route: String) -> Color {
    switch route.uppercased() {
    case "RED": return CTAColors.redLineRed
    case "BLUE": return CTAColors.blueLineBlue
    case "BROWN", "BRN": return CTAColors.brownLineBrown
    case "GREEN", "G": return CTAColors.greenLineGreen
    case "ORANGE": return CTAColors.orangeLineOrange
    case "PINK": return CTAColors.pinkLinePink
    case "PURPLE", "P": return CTAColors.purpleLinePurple
    case "YELLOW", "Y": return CTAColors.yellowLineYellow
    default: return CTAColors.signGrey
    }
}

enum CTAColors {
    /// Red Line Red - Pantone 186C #c60c30
    static let redLineRed = Color(red: 227/255.0, green: 25/255.0, blue: 55/255.0)
    /// Blue Line Blue - Pantone 299C #00a1de
    static let blueLineBlue = Color(red: 0/255.0, green: 157/255.0, blue: 220/255.0)
    /// Brown Line Brown - Pantone 161C #62361b
    static let brownLineBrown = Color(red: 118/255.0, green: 66/255.0, blue: 0/255.0)
    /// Green Line Green - Pantone 355C #009b3a
    static let greenLineGreen = Color(red: 0/255.0, green: 169/255.0, blue: 79/255.0)
    /// Orange Line Orange - Pantone 172C #f9461c
    static let orangeLineOrange = Color(red: 244/255.0, green: 120/255.0, blue: 54/255.0)
    /// Purple Line Purple - Pantone 267C #522398
    static let purpleLinePurple = Color(red: 73/255.0, green: 47/255.0, blue: 146/255.0)
    /// Pink Line Pink - Pantone 204C #e27ea6
    static let pinkLinePink = Color(red: 243/255.0, green: 139/255.0, blue: 185/255.0)
    /// Yellow Line Yellow - Pantone 012C #f9e300
    static let yellowLineYellow = Color(red: 255/255.0, green: 232/255.0, blue: 0/255.0)
    /// Sign Grey - Pantone 425C #565a5c
    static let signGrey = Color(red: 86/255.0, green: 90/255.0, blue: 92/255.0)
}

// MARK: - Line Badge (train_lines.png: colored rect, white bold text)

struct CTALineBadge: View {
    let line: String
    let compact: Bool
    
    init(_ line: String, compact: Bool = false) {
        self.line = line
        self.compact = compact
    }
    
    var body: some View {
        Text(compact ? line : "\(line) Line")
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, 6)
            .background(ctaLineColor(line))
            .cornerRadius(6)
    }
}

// MARK: - Status Indicators (train_lines.png)

struct CTANormalServiceIndicator: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(CTAColors.greenLineGreen)
                .frame(width: 10, height: 10)
            Text("Normal Service")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

struct CTAAlertIndicator: View {
    let text: String
    
    init(_ text: String = "Special Note") {
        self.text = text
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle.fill")
                .font(.subheadline)
                .foregroundColor(CTAColors.blueLineBlue)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

struct CTABypassedIndicator: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle.fill")
                .font(.subheadline)
                .foregroundColor(CTAColors.blueLineBlue)
            Text("Station(s) Bypassed")
                .font(.subheadline)
                .foregroundColor(CTAColors.orangeLineOrange)
        }
    }
}

// MARK: - Route Diagram Row (stops.png: vertical line, circle, station, connections)

struct CTARouteDiagramRow: View {
    let station: CTAStation
    let lineColor: Color
    let isFirst: Bool
    let isLast: Bool
    let showAccessibility: Bool
    let onTap: () -> Void
    
    init(
        station: CTAStation,
        primaryRoute: String? = nil,
        isFirst: Bool = false,
        isLast: Bool = false,
        showAccessibility: Bool = true,
        onTap: @escaping () -> Void
    ) {
        self.station = station
        self.lineColor = primaryRoute.map { ctaLineColor($0) } ?? ctaLineColor(station.routes.first ?? "")
        self.isFirst = isFirst
        self.isLast = isLast
        self.showAccessibility = showAccessibility
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(lineColor)
                        .frame(width: 4, height: isFirst ? 8 : 4)
                    Circle()
                        .stroke(lineColor, lineWidth: 2)
                        .background(Circle().fill(Color(.systemBackground)))
                        .frame(width: 14, height: 14)
                    Rectangle()
                        .fill(lineColor)
                        .frame(width: 4, height: isLast ? 8 : 4)
                }
                .frame(width: 14)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(station.stationName)
                            .font(.headline)
                            .foregroundColor(CTAColors.blueLineBlue)
                            .underline()
                        if showAccessibility {
                            Image(systemName: "figure.roll")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    if station.routes.count > 1 {
                        HStack(spacing: 6) {
                            ForEach(station.routes, id: \.self) { route in
                                CTALineBadge(route, compact: true)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                        }
                    } else if let r = station.routes.first {
                        CTALineBadge(r, compact: true)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
