//
//  VendorManagementView.swift
//  RentGuard
//
//  Full CRUD vendor directory — landlords add and manage their own tradespeople
//

import SwiftUI
import SwiftData

struct VendorManagementView: View {
    let viewModel: TicketViewModel

    @State private var showAddSheet = false
    @State private var editingVendor: VendorModel?
    @State private var searchText = ""

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            VStack(spacing: 0) {
                header
                searchBar

                if filteredVendors.isEmpty {
                    emptyState
                } else {
                    vendorList
                }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddSheet) {
            VendorFormSheet(
                isPresented: $showAddSheet,
                viewModel: viewModel,
                editingVendor: nil
            )
        }
        .sheet(item: $editingVendor) { vendor in
            VendorFormSheet(
                isPresented: Binding(
                    get: { editingVendor != nil },
                    set: { if !$0 { editingVendor = nil } }
                ),
                viewModel: viewModel,
                editingVendor: vendor
            )
        }
    }

    // MARK: - Data

    private var groupedVendors: [(VendorTrade, [VendorModel])] {
        let filtered = searchText.isEmpty
            ? viewModel.vendors
            : viewModel.vendors.filter {
                $0.name.localizedStandardContains(searchText) ||
                $0.trade.rawValue.localizedStandardContains(searchText) ||
                $0.phoneNumber.localizedStandardContains(searchText)
            }

        let grouped = Dictionary(grouping: filtered) { $0.trade }
        return grouped
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
    }

    private var filteredVendors: [VendorModel] {
        searchText.isEmpty
            ? viewModel.vendors
            : viewModel.vendors.filter {
                $0.name.localizedStandardContains(searchText) ||
                $0.trade.rawValue.localizedStandardContains(searchText) ||
                $0.phoneNumber.localizedStandardContains(searchText)
            }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Vendors")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(viewModel.vendors.count) tradespeople in your directory")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))
            }
            Spacer()

            Button {
                showAddSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.18, green: 0.82, blue: 0.78))
                        .frame(width: 48, height: 48)
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.black)
                }
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.5))

            TextField("Search vendors...", text: $searchText)
                .foregroundStyle(.white)

            if !searchText.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(12)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
    }

    // MARK: - List

    private var vendorList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                ForEach(groupedVendors, id: \.0.rawValue) { trade, vendors in
                    tradeSection(trade: trade, vendors: vendors)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 120)
        }
    }

    private func tradeSection(trade: VendorTrade, vendors: [VendorModel]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 10) {
                Image(systemName: trade.iconName)
                    .foregroundStyle(trade.tint)
                    .font(.system(size: 15, weight: .semibold))
                Text(trade.rawValue)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(vendors.count)")
                    .font(.caption.bold())
                    .foregroundStyle(trade.tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(trade.tint.opacity(0.15), in: Capsule())
            }

            // Vendor cards
            ForEach(vendors, id: \.id) { vendor in
                vendorCard(vendor)
                    .onTapGesture {
                        editingVendor = vendor
                    }
            }
        }
    }

    private func vendorCard(_ vendor: VendorModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                // Trade icon
                ZStack {
                    Circle()
                        .fill(vendor.trade.tint.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: vendor.trade.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(vendor.trade.tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(vendor.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(vendor.ratingDisplay)
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.96, green: 0.73, blue: 0.29))
                }

                Spacer()

                // Availability toggle
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.toggleVendorAvailability(vendor)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(vendor.isAvailable ? Color(red: 0.31, green: 0.82, blue: 0.37) : Color(red: 0.60, green: 0.60, blue: 0.65))
                            .frame(width: 8, height: 8)
                        Text(vendor.isAvailable ? "Active" : "Off")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(vendor.isAvailable ? Color(red: 0.31, green: 0.82, blue: 0.37) : .white.opacity(0.5))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        vendor.isAvailable
                            ? Color(red: 0.31, green: 0.82, blue: 0.37).opacity(0.12)
                            : .white.opacity(0.06),
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
            }

            // Contact details
            HStack(spacing: 20) {
                Label(vendor.phoneNumber, systemImage: "phone.fill")
                if !vendor.email.isEmpty {
                    Label(vendor.email, systemImage: "envelope.fill")
                }
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.55))

            if !vendor.notes.isEmpty {
                Text(vendor.notes)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(vendor.trade.tint.opacity(0.15))
        }
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.deleteVendor(vendor)
                }
            } label: {
                Label("Delete Vendor", systemImage: "trash")
            }

            Button {
                editingVendor = vendor
            } label: {
                Label("Edit Vendor", systemImage: "pencil")
            }

            Button {
                viewModel.toggleVendorAvailability(vendor)
            } label: {
                Label(
                    vendor.isAvailable ? "Mark Unavailable" : "Mark Available",
                    systemImage: vendor.isAvailable ? "pause.circle" : "play.circle"
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.2.slash")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.white.opacity(0.3))

            VStack(spacing: 8) {
                Text("No vendors yet")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white.opacity(0.6))
                Text("Add your plumbers, electricians, and other tradespeople to your directory.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                showAddSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Add Your First Vendor")
                }
                .font(.headline)
                .foregroundStyle(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color(red: 0.18, green: 0.82, blue: 0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.top, 8)

            Spacer()
        }
    }
}

// MARK: - Vendor Form Sheet

private struct VendorFormSheet: View {
    @Binding var isPresented: Bool
    let viewModel: TicketViewModel
    var editingVendor: VendorModel?

    @State private var name: String
    @State private var phoneNumber: String
    @State private var email: String
    @State private var notes: String
    @State private var selectedTrade: VendorTrade
    @State private var rating: Double
    @State private var isAvailable: Bool
    @State private var showDeleteConfirmation = false

    private var isEditing: Bool { editingVendor != nil }
    private var titleText: String { isEditing ? "Edit Vendor" : "Add Vendor" }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty }

    init(isPresented: Binding<Bool>, viewModel: TicketViewModel, editingVendor: VendorModel?) {
        self._isPresented = isPresented
        self.viewModel = viewModel
        self.editingVendor = editingVendor

        if let vendor = editingVendor {
            _name = State(wrappedValue: vendor.name)
            _phoneNumber = State(wrappedValue: vendor.phoneNumber)
            _email = State(wrappedValue: vendor.email)
            _notes = State(wrappedValue: vendor.notes)
            _selectedTrade = State(wrappedValue: vendor.trade)
            _rating = State(wrappedValue: Double(vendor.rating))
            _isAvailable = State(wrappedValue: vendor.isAvailable)
        } else {
            _name = State(wrappedValue: "")
            _phoneNumber = State(wrappedValue: "")
            _email = State(wrappedValue: "")
            _notes = State(wrappedValue: "")
            _selectedTrade = State(wrappedValue: .plumber)
            _rating = State(wrappedValue: 4)
            _isAvailable = State(wrappedValue: true)
        }
    }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.11, blue: 0.18).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text(titleText)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Spacer()

                        if isEditing {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.26))
                            }
                            .padding(.trailing, 8)
                        }

                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Divider().overlay(.white.opacity(0.1))

                    // Trade selector
                    tradeSelector

                    // Name
                    formField(
                        icon: "person.fill", label: "Vendor / Company Name",
                        placeholder: "e.g. John's Plumbing",
                        text: $name
                    )

                    // Phone
                    formField(
                        icon: "phone.fill", label: "Phone Number",
                        placeholder: "e.g. (555) 123-4567",
                        text: $phoneNumber,
                        keyboardType: .phonePad
                    )

                    // Email
                    formField(
                        icon: "envelope.fill", label: "Email",
                        placeholder: "e.g. john@plumbing.com",
                        text: $email,
                        keyboardType: .emailAddress
                    )

                    // Rating
                    ratingPicker

                    // Availability
                    availabilityToggle

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "note.text")
                                .foregroundStyle(Color(red: 0.96, green: 0.73, blue: 0.29))
                                .frame(width: 20)
                            Text("Notes")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.7))
                        }

                        TextEditor(text: $notes)
                            .font(.subheadline)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(height: 100)
                            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 20)

                    // Save button
                    Button {
                        saveVendor()
                    } label: {
                        Text(isEditing ? "Save Changes" : "Add Vendor")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .font(.headline)
                            .foregroundStyle(.black)
                            .background(
                                isValid
                                    ? Color(red: 0.18, green: 0.82, blue: 0.78)
                                    : Color(red: 0.18, green: 0.82, blue: 0.78).opacity(0.3),
                                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                            )
                    }
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.5)
                    .buttonStyle(PressableButtonStyle())
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 40)
                }
            }
        }
        .alert("Delete Vendor?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let vendor = editingVendor {
                    viewModel.deleteVendor(vendor)
                }
                isPresented = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove \(editingVendor?.name ?? "this vendor") from your directory.")
        }
    }

    // MARK: - Form Fields

    private var tradeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "hammer.fill")
                    .foregroundStyle(Color(red: 0.57, green: 0.47, blue: 0.35))
                    .frame(width: 20)
                Text("Trade")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(VendorTrade.allCases, id: \.rawValue) { trade in
                        tradeChip(trade)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func tradeChip(_ trade: VendorTrade) -> some View {
        let isSelected = selectedTrade == trade
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTrade = trade
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: trade.iconName)
                    .font(.system(size: 11, weight: .semibold))
                Text(trade.rawValue)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(isSelected ? .black : trade.tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? trade.tint
                    : trade.tint.opacity(0.2),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }

    private func formField(
        icon: String, label: String, placeholder: String,
        text: Binding<String>, keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
                    .frame(width: 20)
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
            }

            TextField(placeholder, text: text)
                .font(.subheadline)
                .foregroundStyle(.white)
                .keyboardType(keyboardType)
                .padding(14)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1))
                }
        }
        .padding(.horizontal, 20)
    }

    private var ratingPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color(red: 0.96, green: 0.73, blue: 0.29))
                    .frame(width: 20)
                Text("Rating")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(Int(rating))/5")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(red: 0.96, green: 0.73, blue: 0.29))
            }
            .padding(.horizontal, 20)

            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            rating = Double(star)
                        }
                    } label: {
                        Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundStyle(Color(red: 0.96, green: 0.73, blue: 0.29))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var availabilityToggle: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "clock.badge.checkmark")
                    .foregroundStyle(Color(red: 0.31, green: 0.82, blue: 0.37))
                    .frame(width: 20)
                Text("Available for Dispatch")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Toggle("", isOn: $isAvailable)
                .tint(Color(red: 0.18, green: 0.82, blue: 0.78))
                .labelsHidden()
        }
        .padding(14)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }

    // MARK: - Save

    private func saveVendor() {
        guard isValid else { return }

        if let existing = editingVendor {
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.phoneNumber = phoneNumber.trimmingCharacters(in: .whitespaces)
            existing.email = email.trimmingCharacters(in: .whitespaces)
            existing.notes = notes.trimmingCharacters(in: .whitespaces)
            existing.tradeRaw = selectedTrade.rawValue
            existing.rating = Int(rating)
            existing.isAvailable = isAvailable
            viewModel.updateVendor(existing)
        } else {
            let new = VendorModel(
                name: name.trimmingCharacters(in: .whitespaces),
                trade: selectedTrade,
                phoneNumber: phoneNumber.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                rating: Int(rating),
                isAvailable: isAvailable,
                notes: notes.trimmingCharacters(in: .whitespaces),
                typicalResponseHours: 24
            )
            viewModel.addVendor(new)
        }

        isPresented = false
    }
}

#Preview {
    VendorManagementView(viewModel: TicketViewModel())
}
