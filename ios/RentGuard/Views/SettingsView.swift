//
//  SettingsView.swift
//  RentGuard
//
//  Landlord profile editor — name, email, phone, properties, units, preferences, and sign-out
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    let authManager: AuthManager

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [LandlordProfileModel]
    @Query private var properties: [PropertyModel]

    @State private var name = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var companyName = ""

    @State private var autoReplyEnabled = true
    @State private var followUpHours: Double = 48
    @State private var emergencyCallEnabled = true
    @State private var aiConfidenceThreshold: Double = 0.85

    @State private var showPropertyEditor = false
    @State private var editingProperty: PropertyModel?
    @State private var showSavedToast = false
    @State private var showLogoutConfirm = false
    @State private var showSignOutConfirm = false

    private var profile: LandlordProfileModel? { profiles.first }

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    profileCard
                    propertiesCard
                    notificationSettings
                    aiSettings
                    accountActions
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 120)
            }
        }
        .onAppear(perform: loadProfile)
        .sheet(isPresented: $showPropertyEditor) {
            propertyEditorSheet
        }
        .overlay(alignment: .bottom) {
            if showSavedToast {
                savedToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .confirmationDialog(
            "Clear your profile? This removes your saved data and returns to setup.",
            isPresented: $showLogoutConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear Profile", role: .destructive, action: deleteProfile)
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Sign out of RentGuard? Your profile data stays on this device.",
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task { await authManager.signOut() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Settings")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Profile, properties & preferences")
                .font(.callout.weight(.medium))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    // MARK: - Profile Card

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
                    Text(profile?.initials ?? "??")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile?.name ?? "Landlord")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text("\(totalUnitCount) units across \(properties.count) properties")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Divider().overlay(.white.opacity(0.1))

            VStack(spacing: 14) {
                settingsInputRow(
                    iconName: "person.fill", label: "Name",
                    text: $name
                )
                settingsInputRow(
                    iconName: "envelope.fill", label: "Email",
                    text: $email, keyboardType: .emailAddress
                )
                settingsInputRow(
                    iconName: "phone.fill", label: "Phone",
                    text: $phoneNumber, keyboardType: .phonePad
                )
                settingsInputRow(
                    iconName: "briefcase.fill", label: "Company",
                    text: $companyName
                )
            }

            Button(action: saveProfile) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.system(size: 13))
                    Text("Save Changes")
                        .font(.subheadline.weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color(red: 0.18, green: 0.82, blue: 0.78).opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(18)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Properties Card

    private var propertiesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Your Properties", systemImage: "building.columns.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    editingProperty = PropertyModel()
                    showPropertyEditor = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Add")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
                }
                .buttonStyle(PressableButtonStyle())
            }

            if properties.isEmpty {
                emptyPropertiesPlaceholder
            } else {
                ForEach(properties) { property in
                    propertyRow(property)
                }
            }
        }
        .padding(18)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var emptyPropertiesPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "building.2")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.25))
                .modifier(FloatingAnimation(delay: 0))
            Text("No properties added yet")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.45))
            Text("Tap \"Add\" to register your first property with its address and unit count.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func propertyRow(_ property: PropertyModel) -> some View {
        Button {
            editingProperty = property
            showPropertyEditor = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(property.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(property.totalUnitsFormatted)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.18, green: 0.82, blue: 0.78).opacity(0.15), in: Capsule())
                }
                if !property.address.isEmpty {
                    Text(property.fullAddress)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(2)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Property Editor Sheet

    private var propertyEditorSheet: some View {
        NavigationStack {
            ZStack {
                BackgroundView().ignoresSafeArea()

                if let property = editingProperty {
                    ScrollView {
                        VStack(spacing: 18) {
                            propertyEditorField(
                                icon: "house.fill", label: "Property Name",
                                placeholder: "Hilltop Apartments",
                                text: Binding(
                                    get: { property.name },
                                    set: { property.name = $0 }
                                )
                            )
                            propertyEditorField(
                                icon: "mappin.and.ellipse", label: "Street Address",
                                placeholder: "123 Main Street",
                                text: Binding(
                                    get: { property.address },
                                    set: { property.address = $0 }
                                )
                            )
                            HStack(spacing: 12) {
                                propertyEditorField(
                                    icon: "building.2", label: "City",
                                    placeholder: "Austin",
                                    text: Binding(
                                        get: { property.city },
                                        set: { property.city = $0 }
                                    )
                                )
                                propertyEditorField(
                                    icon: "map", label: "State",
                                    placeholder: "TX",
                                    text: Binding(
                                        get: { property.state },
                                        set: { property.state = $0 }
                                    )
                                )
                            }
                            HStack(spacing: 12) {
                                propertyEditorField(
                                    icon: "envelope", label: "ZIP",
                                    placeholder: "78701",
                                    text: Binding(
                                        get: { property.zipCode },
                                        set: { property.zipCode = $0 }
                                    ),
                                    keyboardType: .numberPad
                                )
                                propertyEditorField(
                                    icon: "door.left.hand.open", label: "Units",
                                    placeholder: "8",
                                    text: Binding(
                                        get: { String(property.unitCount) },
                                        set: { property.unitCount = Int($0) ?? 0 }
                                    ),
                                    keyboardType: .numberPad
                                )
                            }

                            Button(action: saveProperty) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save Property")
                                        .font(.headline.weight(.bold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.18, green: 0.82, blue: 0.78), Color(red: 0.09, green: 0.62, blue: 0.74)],
                                        startPoint: .leading, endPoint: .trailing
                                    ),
                                    in: RoundedRectangle(cornerRadius: 16)
                                )
                                .foregroundStyle(.white)
                            }
                            .buttonStyle(PressableButtonStyle())

                            if !properties.contains(where: { $0.id == property.id }) == false {
                                Button(role: .destructive, action: deleteProperty) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trash.fill")
                                        Text("Delete Property")
                                            .font(.headline.weight(.bold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(red: 1.0, green: 0.42, blue: 0.26).opacity(0.18), in: RoundedRectangle(cornerRadius: 16))
                                    .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.26))
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                        }
                        .padding(18)
                    }
                }
            }
            .navigationTitle(editingProperty?.name.isEmpty == false ? editingProperty?.name ?? "Property" : "New Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showPropertyEditor = false }
                }
            }
        }
    }

    private func propertyEditorField(
        icon: String, label: String, placeholder: String,
        text: Binding<String>, keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            TextField(placeholder, text: text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .keyboardType(keyboardType)
                .padding(12)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Notification Settings

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

                Slider(value: $followUpHours, in: 12...96, step: 12)
                    .tint(Color(red: 0.18, green: 0.82, blue: 0.78))

                HStack {
                    Text("12h").font(.caption2).foregroundStyle(.white.opacity(0.4))
                    Spacer()
                    Text("96h").font(.caption2).foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(18)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - AI Settings

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

                Slider(value: $aiConfidenceThreshold, in: 0.5...0.99, step: 0.05)
                    .tint(Color(red: 0.80, green: 0.35, blue: 0.85))

                HStack {
                    Text("Relaxed").font(.caption2).foregroundStyle(.white.opacity(0.4))
                    Spacer()
                    Text("Strict").font(.caption2).foregroundStyle(.white.opacity(0.4))
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

    // MARK: - Account Actions

    private var accountActions: some View {
        VStack(spacing: 16) {
            if let user = authManager.user {
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Text("RentGuard v1.0")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))

            Button {
                showSignOutConfirm = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white.opacity(0.7))
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())

            Button(role: .destructive, action: { showLogoutConfirm = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                    Text("Reset Profile & Data")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.26))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    // MARK: - Toast

    private var savedToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(red: 0.31, green: 0.82, blue: 0.37))
                .font(.system(size: 18))
            Text("Changes saved")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.bottom, 40)
    }

    // MARK: - Actions

    private func loadProfile() {
        guard let profile = profile else { return }
        name = profile.name
        email = profile.email
        phoneNumber = profile.phoneNumber
        companyName = profile.companyName
    }

    private func saveProfile() {
        guard let profile = profile else { return }
        profile.name = name
        profile.email = email
        profile.phoneNumber = phoneNumber
        profile.companyName = companyName
        try? modelContext.save()
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        showSaved()
    }

    private func saveProperty() {
        guard let property = editingProperty else { return }
        if !properties.contains(where: { $0.id == property.id }) {
            modelContext.insert(property)
        }
        try? modelContext.save()
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        showPropertyEditor = false
        showSaved()
    }

    private func deleteProperty() {
        guard let property = editingProperty else { return }
        if let existing = properties.first(where: { $0.id == property.id }) {
            modelContext.delete(existing)
            try? modelContext.save()
        }
        let impact = UIImpactFeedbackGenerator(style: .rigid)
        impact.impactOccurred()
        showPropertyEditor = false
        showSaved()
    }

    private func deleteProfile() {
        if let profile = profile {
            modelContext.delete(profile)
        }
        for property in properties {
            modelContext.delete(property)
        }
        try? modelContext.save()
    }

    private func showSaved() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showSavedToast = true
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showSavedToast = false
            }
        }
    }

    private var totalUnitCount: Int {
        properties.reduce(0) { $0 + $1.unitCount }
    }

    // MARK: - Input Row

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

// MARK: - Shared Subviews

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

#Preview {
    SettingsView(authManager: AuthManager())
        .modelContainer(for: [LandlordProfileModel.self, PropertyModel.self])
}
