//
//  RouteStatusSection.swift
//  CTA Transit Assistant
//
//  'L' route status (train_lines.png style)
//

import SwiftUI

private let linesWithStatus: [(line: String, status: String, isNormal: Bool, isBypassed: Bool)] = [
    ("Red", "Normal Service", true, false),
    ("Blue", "Station(s) Bypassed", false, true),
    ("Brown", "Special Note", false, false),
    ("Green", "Special Note", false, false),
    ("Orange", "Special Note", false, false),
    ("Pink", "Special Note", false, false),
    ("Purple", "Special Note", false, false),
    ("Yellow", "Normal Service", true, false),
]

struct RouteStatusSection: View {
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "train.side.front.car")
                        .font(.title3)
                        .foregroundColor(CTAColors.blueLineBlue)
                    Text("'L' route status")
                        .font(.headline)
                        .foregroundColor(CTAColors.blueLineBlue)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                }
                .padding()
                .background(Color(.secondarySystemBackground))
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(linesWithStatus, id: \.line) { item in
                        HStack(spacing: 12) {
                            CTALineBadge(item.line)
                                .frame(minWidth: 96, alignment: .leading)
                                .fixedSize(horizontal: true, vertical: false)
                            Spacer()
                            if item.isNormal {
                                CTANormalServiceIndicator()
                            } else if item.isBypassed {
                                CTABypassedIndicator()
                            } else {
                                CTAAlertIndicator("Special Note")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color(.systemBackground))
                        Divider()
                    }
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
