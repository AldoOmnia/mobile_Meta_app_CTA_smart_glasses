//
//  RoleSelectView.swift
//  CTA Transit Assistant
//
//  Shown after pairing: Rider vs Train Operator selection
//

import SwiftUI

private let ctaBlue = Color(red: 0, green: 0.184, blue: 0.424)

struct RoleSelectView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("operatorModeEnabled") private var operatorModeEnabled = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("How will you use the app?")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            VStack(spacing: 16) {
                Button {
                    appState.userRoleSelected = true
                    appState.isOperatorMode = false
                    operatorModeEnabled = false
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundStyle(ctaBlue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("I'm a Rider")
                                .font(.headline)
                            Text("Arrivals, nearest trains, safety recording")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                Button {
                    appState.userRoleSelected = true
                    appState.isOperatorMode = true
                    operatorModeEnabled = true
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "person.badge.key.fill")
                            .font(.title2)
                            .foregroundStyle(ctaBlue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("I'm a Train Operator")
                                .font(.headline)
                            Text("Service alerts, schedule info, in-glasses notifications")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
