//
//  TicketDetailView.swift
//  RentGuard
//
//  Full ticket detail with AI workflow timeline, vendor assignment,
//  appointment scheduling, and SMS auto-reply view.
//

import SwiftUI

struct TicketDetailView: View {
    let ticket: TenantTicketModel
    let viewModel: TicketViewModel

    @State private var showNoteSheet = false
    @State private var newNote = ""
    @State private var showResolvedConfirmation = false
    @State private var showScheduleSheet = false
    @State private var showVendorPicker = false

    private let aiService = AIWorkflowService()

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    priorityHeader
                    messageCard
                    tenantInfoCard
                    workflowTimeline
                    actionButtons
                    notesCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Ticket")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(
            Color(red: 0.02, green: 0.06, blue: 0.10),
            for: .navigationBar
        )
        .sheet(isPresented: $showNoteSheet) {
            noteSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showScheduleSheet) {
            scheduleAppointmentSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("Ticket Resolved?", isPresented: $showResolvedConfirmation) {
            Button("Mark Resolved", role: .destructive) {
                viewModel.resolveTicket(ticket)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The tenant will be notified that their issue has been resolved.")
        }
    }

    // MARK: - Header

    private var priorityHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(ticket.category.tint.opacity(0.18))
                    .frame(width: 64, height: 64)
                Image(systemName: ticket.category.iconName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(ticket.category.tint)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(ticket.category.rawValue)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(ticket.category.tint)
                    priorityBadge
                    statusBadge
                }
                Text("Created \(ticket.createdAt.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(ticket.category.tint.opacity(0.2))
        }
    }

    // MARK: - Message Card

    private var messageCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Tenant Message", systemImage: "bubble.left.fill")
                .font(.headline)
                .foregroundStyle(.white)

            // SMS bubble style
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(ticket.category.tint.opacity(0.3))
                    .frame(width: 38, height: 38)
                    .overlay {
                        Text(String(ticket.tenantName.prefix(1)))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(ticket.category.tint)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(ticket.tenantName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.8))
                    Text(ticket.message)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(ticket.createdAt.formatted(.dateTime.hour().minute()))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.35))
                }
                .padding(14)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            if ticket.hasPhoto {
                HStack(spacing: 8) {
                    Image(systemName: "photo.fill")
                        .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
                    Text("Photo attached by tenant")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Button {} label: {
                        Text("View")
                            .font(.caption.bold())
                            .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
                    }
                }
                .padding(12)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
            }

            // AI confidence indicator
            HStack {
                Label("AI confidence: \(Int(ticket.aiConfidence * 100))%", systemImage: "brain.head.profile")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
                Spacer()
                if ticket.escalationCount > 0 {
                    Text("Escalated \(ticket.escalationCount)x")
                        .font(.caption.bold())
                        .foregroundStyle(Color(red: 0.80, green: 0.35, blue: 0.85))
                }
            }
        }
        .padding(18)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Tenant Info

    private var tenantInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Tenant Info", systemImage: "person.crop.circle.fill")
                .font(.headline)
                .foregroundStyle(.white)

            DetailRow(iconName: "person.fill", label: "Name", value: ticket.tenantName)
            Divider().overlay(.white.opacity(0.1))
            DetailRow(iconName: "house.fill", label: "Unit", value: ticket.unit)
            if !ticket.phoneNumber.isEmpty {
                Divider().overlay(.white.opacity(0.1))
                DetailRow(iconName: "phone.fill", label: "Phone", value: ticket.phoneNumber)
            }
        }
        .padding(18)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - AI Workflow Timeline

    private var workflowTimeline: some View {
        let vendor = viewModel.vendor(named: ticket.assignedVendorName)
        let appointment = viewModel.appointment(for: ticket.id)
        let steps = aiService.buildTimeline(for: ticket, vendor: vendor, appointment: appointment)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("AI Workflow", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
                Spacer()
                if ticket.status != .resolved && ticket.status != .escalated {
                    Button {
                        viewModel.runAIPipeline(on: ticket)
                    } label: {
                        Label("Re-run AI", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption.bold())
                            .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
                    }
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    timelineRow(step: step)
                }
            }
            .padding(14)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(18)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(red: 0.18, green: 0.82, blue: 0.78).opacity(0.2))
        }
    }

    private func timelineRow(step: WorkflowStep) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Left: timeline dot and line
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(step.isComplete ? step.tint.swiftUIColor.opacity(0.2) : .clear)
                        .frame(width: 34, height: 34)
                    Circle()
                        .stroke(step.tint.swiftUIColor, lineWidth: 2)
                        .frame(width: 34, height: 34)
                    Image(systemName: step.iconName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(step.tint.swiftUIColor)
                }

                if !step.isLast {
                    Rectangle()
                        .fill(step.tint.swiftUIColor.opacity(0.3))
                        .frame(width: 2, height: 32)
                }
            }

            // Right: content
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(step.isComplete ? .white : .white.opacity(0.6))

                Text(step.detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)

                Text(step.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.bottom, step.isLast ? 0 : 4)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if ticket.status != .resolved {
                // Primary: Schedule / Confirm appointment
                let appointment = viewModel.appointment(for: ticket.id)
                if appointment != nil && appointment?.status == .proposed {
                    HStack(spacing: 12) {
                        Button {
                            viewModel.confirmAppointment(appointment!)
                        } label: {
                            Label("Tenant Confirmed", systemImage: "checkmark.bubble.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.black)
                                .background(Color(red: 0.31, green: 0.82, blue: 0.37), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(PressableButtonStyle())

                        Button {
                            viewModel.declineAppointment(appointment!)
                        } label: {
                            Label("Declined", systemImage: "xmark.bubble.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                                .background(Color(red: 1.0, green: 0.42, blue: 0.26).opacity(0.3), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                } else {
                    // Schedule appointment button
                    Button {
                        showScheduleSheet = true
                    } label: {
                        Label(
                            appointment != nil ? "Reschedule Appointment" : "Schedule Appointment",
                            systemImage: "calendar.badge.plus"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .font(.headline)
                        .foregroundStyle(.black)
                        .background(Color(red: 0.18, green: 0.82, blue: 0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(PressableButtonStyle())
                }

                // Mark Resolved
                Button {
                    showResolvedConfirmation = true
                } label: {
                    Label("Mark Resolved", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())

                // Secondary actions
                HStack(spacing: 12) {
                    Button {
                        viewModel.escalateTicket(ticket)
                    } label: {
                        Label("Escalate", systemImage: "arrow.up.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(PressableButtonStyle())

                    Button {
                        viewModel.scheduleFollowUp(ticket)
                    } label: {
                        Label("48h Follow-up", systemImage: "clock.arrow.2.circlepath")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(Color(red: 0.31, green: 0.82, blue: 0.37))
                    Text("Resolved on \(ticket.resolvedAt?.formatted(date: .abbreviated, time: .shortened) ?? "")")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
    }

    // MARK: - Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Notes", systemImage: "note.text")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    showNoteSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
                }
            }

            if ticket.notes.isEmpty {
                Text("No notes yet. Add one to track your actions.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.vertical, 8)
            } else {
                Text(ticket.notes)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Schedule Appointment Sheet

    private var scheduleAppointmentSheet: some View {
        ScheduleAppointmentSheet(
            ticket: ticket,
            viewModel: viewModel,
            isPresented: $showScheduleSheet
        )
    }

    // MARK: - Note Sheet

    private var noteSheet: some View {
        ZStack {
            Color(red: 0.05, green: 0.11, blue: 0.18).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Add Note")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.top, 20)

                TextEditor(text: $newNote)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(14)
                    .frame(height: 160)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)

                Button {
                    if !newNote.isEmpty {
                        viewModel.addNote(ticket, note: newNote)
                        newNote = ""
                        showNoteSheet = false
                    }
                } label: {
                    Text("Save Note")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .font(.headline)
                        .foregroundStyle(.black)
                        .background(Color(red: 0.18, green: 0.82, blue: 0.78), in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(newNote.isEmpty)
                .opacity(newNote.isEmpty ? 0.5 : 1)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Badges

    private var priorityBadge: some View {
        Text("P\(ticket.priority)")
            .font(.caption.bold())
            .foregroundStyle(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(ticket.category.tint, in: Capsule())
    }

    private var statusBadge: some View {
        Text(ticket.status.rawValue)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(ticket.status.tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(ticket.status.tint.opacity(0.15), in: Capsule())
    }
}

// MARK: - Schedule Appointment Sheet

private struct ScheduleAppointmentSheet: View {
    let ticket: TenantTicketModel
    let viewModel: TicketViewModel
    @Binding var isPresented: Bool

    @State private var selectedVendor: VendorModel?
    @State private var proposedDate: Date
    @State private var step: ScheduleStep = .selectVendor
    @State private var showDatePicker = false

    private let aiService = AIWorkflowService()

    enum ScheduleStep {
        case selectVendor
        case confirmDetails
    }

    init(ticket: TenantTicketModel, viewModel: TicketViewModel, isPresented: Binding<Bool>) {
        self.ticket = ticket
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._proposedDate = State(wrappedValue: AIWorkflowService().suggestAppointment())
    }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.08, blue: 0.14).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(step == .selectVendor ? "Schedule Appointment" : "Review & Send")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
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
                .padding(.bottom, 16)

                Divider().overlay(.white.opacity(0.1))

                if step == .selectVendor {
                    vendorSelectionView
                } else {
                    confirmationView
                }
            }
        }
    }

    // MARK: - Step 1: Select Vendor

    private var vendorSelectionView: some View {
        let availableVendors = viewModel.availableVendorsForTicket(ticket)

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Issue summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Issue")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(ticket.message)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // AI recommended vendor
                if let bestVendor = viewModel.availableVendorsForTicket(ticket).first {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("AI Recommendation", systemImage: "sparkles")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))

                        vendorCard(bestVendor, isRecommended: true)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedVendor = bestVendor
                                }
                            }
                    }
                    .padding(.horizontal, 20)
                }

                // Vendor list
                VStack(alignment: .leading, spacing: 10) {
                    Text("All Available Vendors")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 20)

                    ForEach(availableVendors, id: \.id) { vendor in
                        vendorCard(vendor, isRecommended: false)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedVendor = vendor
                                }
                            }
                            .padding(.horizontal, 20)
                    }
                }

                Spacer().frame(height: 100)
            }
        }

        // Bottom button
        .safeAreaInset(edge: .bottom) {
            Button {
                if selectedVendor != nil {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        proposedDate = aiService.suggestAppointment(vendor: selectedVendor)
                        step = .confirmDetails
                    }
                }
            } label: {
                Text("Continue with \(selectedVendor?.name ?? "Vendor")")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .font(.headline)
                    .foregroundStyle(.black)
                    .background(
                        selectedVendor != nil
                            ? Color(red: 0.18, green: 0.82, blue: 0.78)
                            : Color(red: 0.18, green: 0.82, blue: 0.78).opacity(0.3),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }
            .disabled(selectedVendor == nil)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .background(Color(red: 0.04, green: 0.08, blue: 0.14))
        }
    }

    private func vendorCard(_ vendor: VendorModel, isRecommended: Bool) -> some View {
        let isSelected = selectedVendor?.id == vendor.id

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(vendor.trade.tint.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: vendor.trade.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(vendor.trade.tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(vendor.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    if isRecommended {
                        Text("BEST MATCH")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(red: 0.18, green: 0.82, blue: 0.78), in: Capsule())
                    }
                }
                Text("\(vendor.trade.rawValue) · \(vendor.ratingDisplay)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                if vendor.isAvailableNow {
                    Text("Available now")
                        .font(.caption2)
                        .foregroundStyle(Color(red: 0.31, green: 0.82, blue: 0.37))
                } else {
                    Text("Available in \(vendor.typicalResponseHours)h")
                        .font(.caption2)
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.26))
                }
            }

            Spacer()

            Text(vendor.phoneNumber)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))

            // Selection indicator
            ZStack {
                Circle()
                    .stroke(isSelected ? Color(red: 0.18, green: 0.82, blue: 0.78) : .white.opacity(0.2), lineWidth: 2)
                    .frame(width: 24, height: 24)
                if isSelected {
                    Circle()
                        .fill(Color(red: 0.18, green: 0.82, blue: 0.78))
                        .frame(width: 16, height: 16)
                }
            }
        }
        .padding(14)
        .background(
            isSelected ? Color(red: 0.18, green: 0.82, blue: 0.78).opacity(0.1) : .white.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isSelected
                        ? Color(red: 0.18, green: 0.82, blue: 0.78).opacity(0.5)
                        : .white.opacity(0.06)
                )
        }
    }

    // MARK: - Step 2: Confirm Details

    private var confirmationView: some View {
        let vendor = selectedVendor
        let reply = vendor.map {
            aiService.generateReply(
                tenantName: ticket.tenantName,
                issue: ticket.message,
                vendorName: $0.name,
                vendorPhone: $0.phoneNumber,
                appointmentDate: proposedDate
            )
        } ?? ""

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Appointment Details")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Selected vendor
                vendorCard(vendor!, isRecommended: true)
                    .padding(.horizontal, 20)

                // Date/Time picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Date & Time")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)

                    DatePicker(
                        "Proposed appointment",
                        selection: $proposedDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .colorScheme(.dark)
                    .tint(Color(red: 0.18, green: 0.82, blue: 0.78))
                    .padding(8)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20)

                // Auto-reply preview
                VStack(alignment: .leading, spacing: 10) {
                    Label("Auto-Reply Preview", systemImage: "bubble.left.and.text.bubble.right.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))

                    Text(reply)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(alignment: .topTrailing) {
                            Text("SMS")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white.opacity(0.4))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.white.opacity(0.1), in: Capsule())
                                .padding(8)
                        }
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 100)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                // Primary: schedule
                Button {
                    guard let vendor else { return }
                    viewModel.scheduleAppointment(for: ticket, vendor: vendor, date: proposedDate)
                    isPresented = false
                } label: {
                    Label("Send SMS & Schedule", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .font(.headline)
                        .foregroundStyle(.black)
                        .background(Color(red: 0.18, green: 0.82, blue: 0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())

                // Back
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        step = .selectVendor
                    }
                } label: {
                    Text("Change Vendor")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .background(Color(red: 0.04, green: 0.08, blue: 0.14))
        }
    }
}

// MARK: - Shared Components

private struct DetailRow: View {
    let iconName: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
                .frame(width: 22)
            Text(label)
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 55, alignment: .leading)
            Text(value)
                .foregroundStyle(.white)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
