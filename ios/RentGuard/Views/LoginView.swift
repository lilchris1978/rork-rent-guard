//
//  LoginView.swift
//  RentGuard
//
//  Landlord onboarding — profile setup, properties, and units
//

import SwiftUI
import SwiftData

struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var companyName = ""

    @State private var properties: [EditableProperty] = [EditableProperty()]
    @State private var showSaveConfirmation = false

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    headerSection
                    profileSection
                    propertiesSection
                    Spacer().frame(height: 8)
                    saveButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }
        }
        .overlay(alignment: .bottom) {
            if showSaveConfirmation {
                confirmationToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.18, green: 0.82, blue: 0.78), Color(red: 0.09, green: 0.62, blue: 0.74)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                Text("RentGuard")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text("Set up your profile to start managing tenants, vendors, and repairs from one place.")
                .font(.subheadline)
                .foregroundStyle(Color(white: 1, opacity: 0.6))
                .lineSpacing(3)
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionLabel("Your Information", icon: "person.text.rectangle.fill")

            VStack(spacing: 14) {
                InputField(
                    icon: "person.fill",
                    label: "Full Name",
                    placeholder: "Alex Morgan",
                    text: $name
                )
                InputField(
                    icon: "envelope.fill",
                    label: "Email Address",
                    placeholder: "alex@morganproperties.com",
                    text: $email,
                    keyboardType: .emailAddress
                )
                InputField(
                    icon: "phone.fill",
                    label: "Phone Number",
                    placeholder: "(555) 123-4567",
                    text: $phoneNumber,
                    keyboardType: .phonePad
                )
                InputField(
                    icon: "briefcase.fill",
                    label: "Company Name",
                    placeholder: "Morgan Properties LLC",
                    text: $companyName
                )
            }
            .padding(18)
            .background { RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color(white: 1).opacity(0.07)) }
        }
    }

    // MARK: - Properties Section

    private var propertiesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionLabel("Your Properties", icon: "building.columns.fill")
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                        properties.append(EditableProperty())
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("Add")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
                }
            }

            ForEach(properties.indices, id: \.self) { index in
                propertyCard(at: index)
            }
        }
    }

    private func propertyCard(at index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Property \(index + 1)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
                Spacer()
                if properties.count > 1 {
                    Button {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                            var updated = properties
                            updated.remove(at: index)
                            properties = updated
                        }
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.26))
                    }
                }
            }

            InputField(
                icon: "house.fill",
                label: "Property Name",
                placeholder: "Hilltop Apartments",
                text: $properties[index].name
            )
            InputField(
                icon: "mappin.and.ellipse",
                label: "Street Address",
                placeholder: "123 Main Street",
                text: $properties[index].address
            )

            HStack(spacing: 10) {
                InputField(
                    icon: "building.2",
                    label: "City",
                    placeholder: "Austin",
                    text: $properties[index].city
                )
                InputField(
                    icon: "map",
                    label: "State",
                    placeholder: "TX",
                    text: $properties[index].state
                )
            }

            HStack(spacing: 10) {
                InputField(
                    icon: "envelope",
                    label: "ZIP",
                    placeholder: "78701",
                    text: $properties[index].zipCode,
                    keyboardType: .numberPad
                )
                InputField(
                    icon: "door.left.hand.open",
                    label: "Units",
                    placeholder: "8",
                    text: $properties[index].unitCount,
                    keyboardType: .numberPad
                )
            }
        }
        .padding(18)
        .background { RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color(white: 1).opacity(0.07)) }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(red: 0.18, green: 0.82, blue: 0.78, opacity: 0.3), lineWidth: 1)
        )
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            saveProfile()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                Text(isValid ? "Save & Continue" : "Fill Required Fields")
                    .font(.headline.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                isValid
                    ? LinearGradient(
                        colors: [Color(red: 0.18, green: 0.82, blue: 0.78), Color(red: 0.09, green: 0.62, blue: 0.74)],
                        startPoint: .leading, endPoint: .trailing
                    )
                    : LinearGradient(
                        colors: [Color(white: 1, opacity: 0.15), Color(white: 1, opacity: 0.1)],
                        startPoint: .leading, endPoint: .trailing
                    )
            )
            .clipShape(.rect(cornerRadius: 18))
        }
        .disabled(!isValid)
    }

    // MARK: - Confirmation Toast

    private var confirmationToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(red: 0.31, green: 0.82, blue: 0.37))
                .font(.system(size: 18))
            Text("Profile saved — welcome to RentGuard")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.bottom, 40)
    }

    // MARK: - Helpers

    private var isValid: Bool {
        !name.isEmpty && !email.isEmpty
    }

    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
            Text(text)
                .font(.headline)
                .foregroundStyle(.white)
        }
    }

    private func saveProfile() {
        guard isValid else { return }

        // Save landlord profile
        let profile = LandlordProfileModel(
            name: name,
            email: email,
            phoneNumber: phoneNumber,
            companyName: companyName
        )
        modelContext.insert(profile)

        // Save properties
        for prop in properties {
            let property = PropertyModel(
                name: prop.name,
                address: prop.address,
                city: prop.city,
                state: prop.state,
                zipCode: prop.zipCode,
                unitCount: Int(prop.unitCount) ?? 0
            )
            modelContext.insert(property)
        }

        do {
            try modelContext.save()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showSaveConfirmation = true
            }
        } catch {
            print("Failed to save profile: \(error)")
        }
    }
}

// MARK: - Editable Property (local state)

struct EditableProperty {
    var name = ""
    var address = ""
    var city = ""
    var state = ""
    var zipCode = ""
    var unitCount = ""

    var isValid: Bool {
        !name.isEmpty && !address.isEmpty
    }
}

// MARK: - Reusable Input Field

private struct InputField: View {
    let icon: String
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(white: 1, opacity: 0.4))
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(white: 1, opacity: 0.4))
            }
            TextField(placeholder, text: $text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                .padding(12)
                .background { RoundedRectangle(cornerRadius: 12).fill(Color(white: 1).opacity(0.06)) }
        }
    }
}

#Preview {
    LoginView()
        .modelContainer(for: [LandlordProfileModel.self, PropertyModel.self])
}
