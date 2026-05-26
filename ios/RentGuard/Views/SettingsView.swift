//
//  SettingsView.swift
//  RentGuard
//
//  Landlord profile, property management, and notification preferences
//

import SwiftUI

struct SettingsView: View {
    @State private var landlordName = "Alex Morgan"
    @State private var propertyCount = "3"
    @State private var unitCount = "23"
    @State private var autoReplyEnabled = true
    @State private var followUpHours: Double = 48
    @State private var emergencyCallEnabled = true
    @State private var aiConfidenceThreshold: Double = 0.85

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    profileCard
                    notificationSettings
                    aiSettings
                    aboutCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 120)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Settings")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Profile & preferences")
                .font(.callout.weight(.medium))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.18, green: 0.82, blue: 0.78), Color(red: 0.09, green: 0.62, blue: 0.74)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    Text(String(landlordName.prefix(2)))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(landlordName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text("\(propertyCount) properties · \(unitCount) units")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Divider().overlay(.white.opacity(0.1))

            VStack(spacing: 14) {
                settingsInputRow(
                    iconName: "person.fill", label: "Name",
                    text: $landlordName
                )
                settingsInputRow(
                    iconName: "building.2.fill", label: "Properties",
                    text: $propertyCount, keyboardType: .numberPad
                )
                settingsInputRow(
                    iconName: "house.fill", label: "Total Units",
                    text: $unitCount, keyboardType: .numberPad
                )
            }
        }
        .padding(18)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var notificationSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notifications")
                .font(.headline)
                .foregroundStyle(.white)

            ToggleRow(
                iconName: "message.badge.filled.fill",
                iconColor: Color(red: 0.18, green: 0.82, blue: 0.78),
                title: "AI Auto-Replies",
                subtitle: "Send instant acknowledgment to tenants",
                isOn: $autoReplyEnabled
            )

            Divider().overlay(.white.opacity(0.1))

            ToggleRow(
                iconName: "phone.badge.waveform.fill",
                iconColor: Color(red: 1.0, green: 0.42, blue: 0.26),
                title: "Emergency Call Alerts",
                subtitle: "Get a phone call for gas, fire, flood emergencies",
                isOn: $emergencyCallEnabled
            )

            Divider().overlay(.white.opacity(0.1))

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "clock.badge")
                        .foregroundStyle(Color(red: 0.96, green: 0.73, blue: 0.29))
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Follow-up Window")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Text("Auto-text tenant after \(Int(followUpHours)) hours")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }

                Slider(value: $followUpHours, in: 12...96, step: 12) {
                    Text("Follow-up hours")
                }
                .tint(Color(red: 0.18, green: 0.82, blue: 0.78))

                HStack {
                    Text("12h")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                    Text("96h")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(18)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var aiSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Configuration")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(Color(red: 0.80, green: 0.35, blue: 0.85))
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Classification Threshold")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Text("AI confidence below \(Int(aiConfidenceThreshold * 100))% flags for human review")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }

                Slider(value: $aiConfidenceThreshold, in: 0.5...0.99, step: 0.05) {
                    Text("AI threshold")
                }
                .tint(Color(red: 0.80, green: 0.35, blue: 0.85))

                HStack {
                    Text("Relaxed")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                    Text("Strict")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            Divider().overlay(.white.opacity(0.1))

            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(Color(red: 0.31, green: 0.82, blue: 0.37))
                    Text("Integration Status")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    Spacer()
                    Text("Connected")
                        .font(.caption.bold())
                        .foregroundStyle(Color(red: 0.31, green: 0.82, blue: 0.37))
                }

                HStack(spacing: 8) {
                    IntegrationBadge(name: "Twilio", connected: true)
                    IntegrationBadge(name: "Airtable", connected: true)
                    IntegrationBadge(name: "ClickUp", connected: true)
                    IntegrationBadge(name: "OpenAI", connected: true)
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var aboutCard: some View {
        VStack(spacing: 16) {
            Text("RentGuard v1.0")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
            Text("AI-powered landlord assistant. Built with Rork.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func settingsInputRow(
        iconName: String, label: String,
        text: Binding<String>, keyboardType: UIKeyboardType = .default
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 90, alignment: .leading)

            TextField("", text: text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .keyboardType(keyboardType)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct ToggleRow: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(Color(red: 0.18, green: 0.82, blue: 0.78))
                .labelsHidden()
        }
    }
}

private struct IntegrationBadge: View {
    let name: String
    let connected: Bool

    var body: some View {
        Text(name)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(connected ? Color(red: 0.31, green: 0.82, blue: 0.37) : .white.opacity(0.4))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                connected
                    ? Color(red: 0.31, green: 0.82, blue: 0.37).opacity(0.12)
                    : .white.opacity(0.07),
                in: Capsule()
            )
    }
}
