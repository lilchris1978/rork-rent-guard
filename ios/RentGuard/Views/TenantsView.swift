//
//  TenantsView.swift
//  RentGuard
//
//  Tenant directory — manual entry, contacts import, CSV import
//

import SwiftUI
import SwiftData
import ContactsUI
import UniformTypeIdentifiers

struct TenantsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TenantModel.name) private var tenants: [TenantModel]
    @Query private var properties: [PropertyModel]

    @State private var searchText = ""
    @State private var showAddSheet = false
    @State private var showContactPicker = false
    @State private var showCSVImporter = false
    @State private var showDeleteConfirm = false
    @State private var tenantToDelete: TenantModel?
    @State private var showSavedToast = false
    @State private var selectedImportMode: ImportMode = .manual

    // Manual entry state
    @State private var newName = ""
    @State private var newPhone = ""
    @State private var newEmail = ""
    @State private var newUnit = ""
    @State private var newProperty = ""
    @State private var newLeaseStart = Date()
    @State private var newLeaseEnd = Date().addingTimeInterval(365 * 86400)
    @State private var newNotes = ""
    @State private var hasLease = false

    // CSV import state
    @State private var csvText = ""
    @State private var csvPreview: [[String]] = []
    @State private var csvError: String?

    enum ImportMode: String, CaseIterable {
        case manual = "Manual"
        case contacts = "Contacts"
        case csv = "CSV"
    }

    private var filteredTenants: [TenantModel] {
        if searchText.isEmpty { return tenants }
        return tenants.filter {
            $0.name.localizedStandardContains(searchText) ||
            $0.unit.localizedStandardContains(searchText) ||
            $0.phoneNumber.localizedStandardContains(searchText) ||
            $0.email.localizedStandardContains(searchText) ||
            $0.propertyName.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection

                // Search
                searchBar
                    .padding(.horizontal, 18)
                    .padding(.top, 10)

                // Content
                if filteredTenants.isEmpty && tenants.isEmpty {
                    emptyState
                } else if filteredTenants.isEmpty {
                    noResultsState
                } else {
                    tenantList
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showSavedToast {
                toastView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showAddSheet) {
            addTenantSheet
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView { contact in
                importFromContact(contact)
            }
        }
        .confirmationDialog(
            "Delete \(tenantToDelete?.name ?? "tenant")?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteTenant()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Tenants")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(tenants.count) in your directory")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))
            }
            Spacer()
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.18, green: 0.82, blue: 0.78), Color(red: 0.09, green: 0.62, blue: 0.74)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.4))
            TextField("Search tenants...", text: $searchText)
                .font(.subheadline)
                .foregroundStyle(.white)
                .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Tenant List

    private var tenantList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(filteredTenants) { tenant in
                    tenantRow(tenant)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.92).combined(with: .opacity),
                            removal: .scale(scale: 0.85).combined(with: .opacity)
                        ))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
    }

    private func tenantRow(_ tenant: TenantModel) -> some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.18, green: 0.82, blue: 0.78).opacity(0.3),
                                Color(red: 0.09, green: 0.62, blue: 0.74).opacity(0.2)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                Text(tenant.initials)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(tenant.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(tenant.displayUnit)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                HStack(spacing: 12) {
                    if !tenant.phoneNumber.isEmpty {
                        Label(tenant.phoneNumber, systemImage: "phone.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    if tenant.hasLease {
                        Label("Lease active", systemImage: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(Color(red: 0.31, green: 0.82, blue: 0.37))
                    }
                }
            }

            Spacer()

            // Context menu
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                tenantToDelete = tenant
                showDeleteConfirm = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.05), in: Circle())
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.06))
        }
    }

    // MARK: - Empty States

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            ZStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.12))
                    .offset(y: -4)
                    .modifier(FloatingAnimation(delay: 0))
                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.18))
                    .offset(x: -20, y: 8)
                    .modifier(FloatingAnimation(delay: 0.5))
                Image(systemName: "person.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white.opacity(0.14))
                    .offset(x: 22, y: 4)
                    .modifier(FloatingAnimation(delay: 1.0))
            }
            .frame(height: 100)

            VStack(spacing: 10) {
                Text("No tenants yet")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
                Text("Tap + to add tenants manually, from your contacts, or import from a spreadsheet.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }

            addTenantMenu
                .padding(.top, 8)

            Spacer().frame(height: 60)
        }
        .frame(maxWidth: .infinity)
    }

    private var noResultsState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.25))
            Text("No tenants match \"\(searchText)\"")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
            Spacer().frame(height: 60)
        }
        .frame(maxWidth: .infinity)
    }

    private var addTenantMenu: some View {
        HStack(spacing: 10) {
            ForEach(ImportMode.allCases, id: \.self) { mode in
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    selectedImportMode = mode
                    switch mode {
                    case .manual:
                        resetForm()
                        showAddSheet = true
                    case .contacts:
                        showContactPicker = true
                    case .csv:
                        csvText = ""
                        csvPreview = []
                        csvError = nil
                        showAddSheet = true
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: modeIcon(for: mode))
                            .font(.system(size: 22))
                        Text(mode.rawValue)
                            .font(.caption.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white.opacity(0.8))
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(.horizontal, 18)
    }

    private func modeIcon(for mode: ImportMode) -> String {
        switch mode {
        case .manual: "square.and.pencil"
        case .contacts: "person.crop.circle.badge.plus"
        case .csv: "tablecells.fill"
        }
    }

    // MARK: - Add Tenant Sheet

    private var addTenantSheet: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.08, blue: 0.14).ignoresSafeArea()

                if selectedImportMode == .csv {
                    csvImportView
                } else {
                    manualEntryView
                }
            }
            .navigationTitle(selectedImportMode == .csv ? "Import CSV" : "New Tenant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if selectedImportMode == .csv {
                        Button("Import \(csvPreview.count)") {
                            importFromCSV()
                        }
                        .disabled(csvPreview.isEmpty || csvError != nil)
                    } else {
                        Button("Save") {
                            saveManualTenant()
                        }
                        .disabled(newName.isEmpty)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Manual Entry

    private var manualEntryView: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 14) {
                    tenantField(icon: "person.fill", label: "Full Name", text: $newName, placeholder: "Maya Chen")
                    tenantField(icon: "phone.fill", label: "Phone Number", text: $newPhone, placeholder: "(555) 123-4567", keyboardType: .phonePad)
                    tenantField(icon: "envelope.fill", label: "Email", text: $newEmail, placeholder: "maya@email.com", keyboardType: .emailAddress)
                }
                .padding(18)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))

                VStack(spacing: 14) {
                    tenantField(icon: "door.left.hand.open", label: "Unit", text: $newUnit, placeholder: "4B")

                    Picker("Property", selection: $newProperty) {
                        Text("None").tag("")
                        ForEach(properties, id: \.name) { prop in
                            Text(prop.name).tag(prop.name)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color(red: 0.18, green: 0.82, blue: 0.78))
                }
                .padding(18)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))

                VStack(spacing: 14) {
                    Toggle(isOn: $hasLease) {
                        Label("Lease Dates", systemImage: "calendar")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                    }
                    .tint(Color(red: 0.18, green: 0.82, blue: 0.78))

                    if hasLease {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("START".uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.4))
                                DatePicker("", selection: $newLeaseStart, displayedComponents: .date)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("END".uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.4))
                                DatePicker("", selection: $newLeaseEnd, displayedComponents: .date)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                        }
                    }
                }
                .padding(18)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))

                VStack(spacing: 10) {
                    Label("Notes", systemImage: "note.text")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextEditor(text: $newNotes)
                        .font(.subheadline)
                        .scrollContentBackground(.hidden)
                        .frame(height: 80)
                        .padding(10)
                        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                .padding(18)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
        }
    }

    // MARK: - CSV Import

    private var csvImportView: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Paste CSV data below")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Format: Name, Phone, Email, Unit, Property, Notes")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                Text("First row is treated as a header and skipped.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.top, 16)

            TextEditor(text: $csvText)
                .font(.system(size: 13, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(12)
                .frame(height: 160)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .onChange(of: csvText) { _, newValue in
                    parseCSV(newValue)
                }

            if let error = csvError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.26))
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.26))
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
            }

            if !csvPreview.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview (\(csvPreview.count) tenants)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)

                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(csvPreview.indices, id: \.self) { idx in
                                let row = csvPreview[idx]
                                HStack {
                                    Text(row.first ?? "")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if row.count > 1 {
                                        Text(row[1])
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                }
                                .padding(12)
                                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                    .frame(maxHeight: 200)
                }
                .padding(.top, 16)
            }

            Spacer()
        }
    }

    private func parseCSV(_ text: String) {
        guard !text.isEmpty else {
            csvPreview = []
            csvError = nil
            return
        }

        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard lines.count > 1 else {
            csvError = "Need at least a header row and one data row"
            csvPreview = []
            return
        }

        let dataLines = Array(lines.dropFirst())
        var rows: [[String]] = []

        for line in dataLines {
            let columns = line.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: "\""))) }
            if !columns.isEmpty && !columns[0].isEmpty {
                rows.append(columns)
            }
        }

        if rows.isEmpty {
            csvError = "No valid data rows found"
        } else {
            csvError = nil
        }

        csvPreview = rows
    }

    private func importFromCSV() {
        guard !csvPreview.isEmpty else { return }

        for row in csvPreview {
            let tenant = TenantModel(
                name: row.indices.contains(0) ? row[0] : "",
                phoneNumber: row.indices.contains(1) ? row[1] : "",
                email: row.indices.contains(2) ? row[2] : "",
                unit: row.indices.contains(3) ? row[3] : "",
                propertyName: row.indices.contains(4) ? row[4] : "",
                notes: row.indices.contains(5) ? row[5] : ""
            )
            modelContext.insert(tenant)
        }

        try? modelContext.save()
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        showSaved()
        showAddSheet = false
    }

    // MARK: - Contacts Import

    private func importFromContact(_ contact: CNContact) {
        let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
        let email = contact.emailAddresses.first?.value as? String ?? ""

        let tenant = TenantModel(name: name, phoneNumber: phone, email: email)
        modelContext.insert(tenant)
        try? modelContext.save()

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        showSaved()
    }

    private func saveManualTenant() {
        guard !newName.isEmpty else { return }

        let tenant = TenantModel(
            name: newName,
            phoneNumber: newPhone,
            email: newEmail,
            unit: newUnit,
            propertyName: newProperty,
            leaseStart: hasLease ? newLeaseStart : nil,
            leaseEnd: hasLease ? newLeaseEnd : nil,
            notes: newNotes
        )
        modelContext.insert(tenant)
        try? modelContext.save()

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        resetForm()
        showSaved()
        showAddSheet = false
    }

    private func deleteTenant() {
        guard let tenant = tenantToDelete else { return }
        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
            modelContext.delete(tenant)
            try? modelContext.save()
        }
        let impact = UIImpactFeedbackGenerator(style: .rigid)
        impact.impactOccurred()
        tenantToDelete = nil
        showSaved()
    }

    private func resetForm() {
        newName = ""
        newPhone = ""
        newEmail = ""
        newUnit = ""
        newProperty = ""
        newLeaseStart = Date()
        newLeaseEnd = Date().addingTimeInterval(365 * 86400)
        newNotes = ""
        hasLease = false
        selectedImportMode = .manual
    }

    // MARK: - Toast

    private var toastView: some View {
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
}

// MARK: - Input Field

private func tenantField(
    icon: String, label: String,
    text: Binding<String>, placeholder: String,
    keyboardType: UIKeyboardType = .default
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
            .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
            .padding(12)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Floating Animation Modifier

struct FloatingAnimation: ViewModifier {
    let delay: Double
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2.5)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    offset = -6
                }
            }
    }
}

// MARK: - Contact Picker

struct ContactPickerView: UIViewControllerRepresentable {
    let onSelect: (CNContact) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.displayedPropertyKeys = [
            CNContactGivenNameKey as String,
            CNContactFamilyNameKey as String,
            CNContactPhoneNumbersKey as String,
            CNContactEmailAddressesKey as String
        ]
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        let onSelect: (CNContact) -> Void

        init(onSelect: @escaping (CNContact) -> Void) {
            self.onSelect = onSelect
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            onSelect(contact)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {}
    }
}

#Preview {
    TenantsView()
        .modelContainer(for: [TenantModel.self, PropertyModel.self])
}
