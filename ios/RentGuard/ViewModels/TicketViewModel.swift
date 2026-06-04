//
//  TicketViewModel.swift
//  RentGuard
//
//  Business logic for managing tenant tickets, vendors, and appointments
//

import Foundation
import SwiftData
import SwiftUI

@Observable @MainActor
final class TicketViewModel {
    private var modelContext: ModelContext?
    var tickets: [TenantTicketModel] = []
    var vendors: [VendorModel] = []
    var appointments: [AppointmentModel] = []
    var selectedFilter: TicketCategory? = nil
    var searchQuery: String = ""
    var selectedTicketID: UUID?
    var notificationService: NotificationService?

    private let aiService = AIWorkflowService()

    // MARK: - Filtered Data

    var filteredTickets: [TenantTicketModel] {
        var result = tickets
        if let selectedFilter {
            result = result.filter { $0.category == selectedFilter }
        }
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.tenantName.localizedStandardContains(searchQuery) ||
                $0.unit.localizedStandardContains(searchQuery) ||
                $0.message.localizedStandardContains(searchQuery)
            }
        }
        return result.sorted { $0.priority < $1.priority }
    }

    var openCount: Int { tickets.filter { $0.status != .resolved }.count }
    var urgentCount: Int { tickets.filter { $0.priority <= 1 && $0.status != .resolved }.count }
    var resolvedTodayCount: Int {
        let calendar = Calendar.current
        return tickets.filter {
            guard let resolvedAt = $0.resolvedAt else { return false }
            return calendar.isDateInToday(resolvedAt)
        }.count
    }
    var averageResponseMinutes: Double {
        let resolved = tickets.filter { $0.resolvedAt != nil }
        guard !resolved.isEmpty else { return 0 }
        let total = resolved.reduce(0.0) { $0 + $1.resolvedAt!.timeIntervalSince($1.createdAt) }
        return total / Double(resolved.count) / 60.0
    }

    var categoryBreakdown: [(TicketCategory, Int)] {
        let active = tickets.filter { $0.status != .resolved }
        return TicketCategory.allCases.map { category in
            (category, active.filter { $0.category == category }.count)
        }
    }

    var upcomingAppointments: [AppointmentModel] {
        appointments.filter { $0.isUpcoming && $0.status != .cancelled && $0.status != .completed }
            .sorted { $0.proposedDate < $1.proposedDate }
    }

    // MARK: - Configuration

    func configure(with context: ModelContext) {
        modelContext = context
        fetchTickets()
        fetchVendors()
        fetchAppointments()
        if tickets.isEmpty {
            seedSampleData()
        }
        if vendors.isEmpty {
            seedVendors()
        }
    }

    // MARK: - Ticket CRUD

    func fetchTickets() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<TenantTicketModel>(sortBy: [SortDescriptor(\.priority)])
        do {
            tickets = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch tickets: \(error)")
        }
    }

    func addTicket(_ ticket: TenantTicketModel) {
        guard let modelContext else { return }
        modelContext.insert(ticket)
        saveAndRefresh()
    }

    func resolveTicket(_ ticket: TenantTicketModel) {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.prepare()
        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
            ticket.status = .resolved
            ticket.resolvedAt = Date()
            // Also complete any associated appointment
            if let appointment = appointment(for: ticket.id) {
                appointment.status = .completed
            }
            notificationService?.cancelNotifications(for: ticket.id)
            saveAndRefresh()
        }
        impact.impactOccurred()
    }

    func escalateTicket(_ ticket: TenantTicketModel) {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.prepare()
        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
            ticket.status = .escalated
            ticket.escalationCount += 1
            ticket.priority = max(1, ticket.priority - 1)
            saveAndRefresh()
        }
        impact.impactOccurred()
        notificationService?.notifyEmergencyTicket(ticket)
    }

    func scheduleFollowUp(_ ticket: TenantTicketModel, hoursFromNow: Double = 48) {
        ticket.followUpAt = Date().addingTimeInterval(hoursFromNow * 3600)
        saveAndRefresh()
        notificationService?.notifyFollowUp(ticket: ticket, inHours: Int(hoursFromNow))
    }

    func addNote(_ ticket: TenantTicketModel, note: String) {
        let existing = ticket.notes.isEmpty ? "" : "\(ticket.notes)\n"
        ticket.notes = "\(existing)[\(Date().formatted(date: .abbreviated, time: .shortened))] \(note)"
        saveAndRefresh()
    }

    // MARK: - Vendor Management

    func fetchVendors() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<VendorModel>(sortBy: [SortDescriptor(\.name)])
        do {
            vendors = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch vendors: \(error)")
        }
    }

    func addVendor(_ vendor: VendorModel) {
        guard let modelContext else { return }
        modelContext.insert(vendor)
        saveAndRefresh()
    }

    func updateVendor(_ vendor: VendorModel) {
        saveAndRefresh()
    }

    func deleteVendor(_ vendor: VendorModel) {
        guard let modelContext else { return }
        modelContext.delete(vendor)
        saveAndRefresh()
    }

    func toggleVendorAvailability(_ vendor: VendorModel) {
        vendor.isAvailable.toggle()
        saveAndRefresh()
    }

    func vendorsForTrade(_ trade: VendorTrade) -> [VendorModel] {
        vendors.filter { $0.trade == trade }
    }

    func availableVendorsForTicket(_ ticket: TenantTicketModel) -> [VendorModel] {
        let neededTrade = VendorTrade.forCategory(ticket.category, message: ticket.message)
        return vendors.filter { $0.trade == neededTrade || $0.trade == .handyman }
            .sorted { ($0.isAvailableNow ? 0 : 1) < ($1.isAvailableNow ? 0 : 1) || $0.rating > $1.rating }
    }

    // MARK: - Appointment Management

    func fetchAppointments() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<AppointmentModel>(sortBy: [SortDescriptor(\.proposedDate)])
        do {
            appointments = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch appointments: \(error)")
        }
    }

    func appointment(for ticketID: UUID) -> AppointmentModel? {
        appointments.first { $0.ticketID == ticketID }
    }

    func addAppointment(_ appointment: AppointmentModel) {
        guard let modelContext else { return }
        modelContext.insert(appointment)
        saveAndRefresh()
    }

    func confirmAppointment(_ appointment: AppointmentModel) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
            appointment.status = .confirmed
            appointment.tenantResponse = .accepted
            appointment.confirmedAt = Date()
            saveAndRefresh()
        }
    }

    func declineAppointment(_ appointment: AppointmentModel) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
            appointment.tenantResponse = .declined
            appointment.status = .cancelled
            saveAndRefresh()
        }
    }

    // MARK: - AI Workflow Pipeline

    /// Runs the complete AI pipeline on an incoming SMS:
    /// 1. Triage → category + priority
    /// 2. Find matching vendor
    /// 3. Suggest appointment time
    /// 4. Generate auto-reply
    /// 5. Create appointment record
    /// 6. Send emergency notification if priority 1
    ///
    /// This is called when a new SMS comes in, or manually from the detail view.
    func runAIPipeline(on ticket: TenantTicketModel) {
        // Step 1: AI triage (already set during creation, but re-run for completeness)
        let (category, priority, triageReason) = aiService.triage(message: ticket.message)
        ticket.categoryRaw = category.rawValue
        ticket.priority = priority
        ticket.nextStep = triageReason

        // Step 2: Find vendor
        if let vendor = aiService.findVendor(for: category, message: ticket.message, vendors: vendors) {
            ticket.assignedVendorName = vendor.name
            ticket.assignedVendorPhone = vendor.phoneNumber
            ticket.assignedVendorTradeRaw = vendor.trade.rawValue
            ticket.status = .vendor
        }

        // Step 3: Suggest appointment
        let vendorModel = aiService.findVendor(for: category, message: ticket.message, vendors: vendors)
        let appointmentDate = aiService.suggestAppointment(vendor: vendorModel)

        // Step 4: Generate reply
        let vendorName = ticket.assignedVendorName.isEmpty ? "our repair team" : ticket.assignedVendorName
        let vendorPhone = ticket.assignedVendorPhone.isEmpty ? "(contact on file)" : ticket.assignedVendorPhone
        let reply = aiService.generateReply(
            tenantName: ticket.tenantName,
            issue: ticket.message,
            vendorName: vendorName,
            vendorPhone: vendorPhone,
            appointmentDate: appointmentDate
        )
        ticket.aiReply = reply

        // Record auto-reply in conversation
        if ticket.messages.isEmpty {
            ticket.appendMessage(sender: .tenant, text: ticket.message)
        }
        ticket.appendMessage(sender: .landlord, text: reply)

        // Step 5: Create appointment record
        let appointment = AppointmentModel(
            ticketID: ticket.id,
            vendorName: vendorName,
            vendorPhone: vendorPhone,
            vendorTrade: VendorTrade.forCategory(category, message: ticket.message),
            proposedDate: appointmentDate,
            status: .proposed,
            tenantResponse: .pending
        )
        addAppointment(appointment)

        saveAndRefresh()

        // Notify if emergency
        if priority <= 1 {
            notificationService?.notifyEmergencyTicket(ticket)
        }
    }

    /// Manually assign a specific vendor to a ticket
    func assignVendor(_ vendor: VendorModel, to ticket: TenantTicketModel) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
            ticket.assignedVendorName = vendor.name
            ticket.assignedVendorPhone = vendor.phoneNumber
            ticket.assignedVendorTradeRaw = vendor.trade.rawValue
            ticket.status = .vendor
            saveAndRefresh()
        }
    }

    /// Manually schedule an appointment for a ticket with a specific vendor and date
    func scheduleAppointment(for ticket: TenantTicketModel, vendor: VendorModel, date: Date) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
            // Update ticket
            ticket.assignedVendorName = vendor.name
            ticket.assignedVendorPhone = vendor.phoneNumber
            ticket.assignedVendorTradeRaw = vendor.trade.rawValue
            ticket.status = .vendor

            // Generate reply
            let reply = aiService.generateReply(
                tenantName: ticket.tenantName,
                issue: ticket.message,
                vendorName: vendor.name,
                vendorPhone: vendor.phoneNumber,
                appointmentDate: date
            )
            ticket.aiReply = reply

            // Record in conversation
            if ticket.messages.isEmpty {
                ticket.appendMessage(sender: .tenant, text: ticket.message)
            }
            ticket.appendMessage(sender: .landlord, text: reply)

            // Create appointment
            let appointment = AppointmentModel(
                ticketID: ticket.id,
                vendorName: vendor.name,
                vendorPhone: vendor.phoneNumber,
                vendorTrade: vendor.trade,
                proposedDate: date,
                status: .proposed,
                tenantResponse: .pending
            )
            addAppointment(appointment)

            saveAndRefresh()
        }
    }

    /// Called when the landlord sends a manual SMS reply
    func sendManualReply(_ text: String, to ticket: TenantTicketModel) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.prepare()
        // Ensure the tenant's original message is in the conversation
        if ticket.messages.isEmpty {
            ticket.appendMessage(sender: .tenant, text: ticket.message)
        }
        // Append the landlord's reply
        ticket.appendMessage(sender: .landlord, text: text)
        ticket.aiReply = text
        ticket.status = .answered
        saveAndRefresh()
        impact.impactOccurred()
    }

    /// Ensures the AI auto-reply is recorded in the conversation history
    func recordAutoReply(_ reply: String, for ticket: TenantTicketModel) {
        if ticket.messages.isEmpty {
            ticket.appendMessage(sender: .tenant, text: ticket.message)
        }
        // Don't duplicate auto-replies that are already in the conversation
        let alreadyRecorded = ticket.messages.contains { $0.sender == .landlord && $0.text == reply }
        if !alreadyRecorded && !reply.isEmpty {
            ticket.appendMessage(sender: .landlord, text: reply)
        }
        saveAndRefresh()
    }

    // MARK: - Helpers

    func vendor(named name: String) -> VendorModel? {
        vendors.first { $0.name == name }
    }

    private func saveAndRefresh() {
        guard let modelContext else { return }
        try? modelContext.save()
        fetchTickets()
        fetchVendors()
        fetchAppointments()
    }

    // MARK: - Seed Data

    private func seedSampleData() {
        let samples: [TenantTicketModel] = [
            TenantTicketModel(
                tenantName: "Maya Chen", unit: "Unit 4B", phoneNumber: "(555) 121-4501",
                category: .emergency, message: "Water is leaking through the bathroom ceiling again. I attached a photo.",
                priority: 1, status: .vendor, hasPhoto: true,
                nextStep: "Water leak detected. AI classified as Emergency P1. Matched to plumber.",
                followUpAt: Date().addingTimeInterval(2 * 3600),
                assignedVendorName: "John's Plumbing",
                assignedVendorPhone: "(555) 881-3042",
                assignedVendorTrade: .plumber,
                aiReply: "Hi Maya, thanks for reporting this. I've categorized your issue as an emergency. I'm sending John's Plumbing ((555) 881-3042) to your unit on Tuesday, May 26 between 9:00 AM — does that work? Reply Y to confirm or R to reschedule."
            ),
            TenantTicketModel(
                tenantName: "Andre Wilson", unit: "Unit 2A", phoneNumber: "(555) 121-4502",
                category: .maintenance, message: "AC stopped blowing cold air this morning. Can someone come tomorrow?",
                priority: 2, status: .vendor, hasPhoto: false,
                nextStep: "HVAC failure detected. Matched to CoolAir HVAC. Appointment proposed.",
                followUpAt: Date().addingTimeInterval(24 * 3600),
                assignedVendorName: "CoolAir HVAC",
                assignedVendorPhone: "(555) 881-5519",
                assignedVendorTrade: .hvac,
                aiReply: "Hi Andre, thanks for reporting this. I've categorized your AC issue as maintenance. I'm sending CoolAir HVAC ((555) 881-5519) to your unit on Tuesday, May 26 between 10:00 AM — does that work? Reply Y to confirm or R to reschedule."
            ),
            TenantTicketModel(
                tenantName: "Nora Patel", unit: "Unit 8C", phoneNumber: "(555) 121-4503",
                category: .payment, message: "Can I pay rent on Friday when payroll hits?",
                priority: 3, status: .review, hasPhoto: false,
                nextStep: "Send polite policy reply and flag late-payment approval for owner review."
            ),
            TenantTicketModel(
                tenantName: "Luis Romero", unit: "Unit 1D", phoneNumber: "(555) 121-4504",
                category: .general, message: "What day is recycling pickup this week?",
                priority: 4, status: .answered, hasPhoto: false,
                nextStep: "Auto-reply with city recycling schedule and close if tenant confirms."
            ),
            TenantTicketModel(
                tenantName: "Priya Shah", unit: "Unit 5F", phoneNumber: "(555) 121-4505",
                category: .emergency, message: "I smell gas near the stove. What should I do?",
                priority: 1, status: .escalated, hasPhoto: false,
                nextStep: "Tell tenant to leave unit, call gas emergency line, and escalate to owner immediately."
            )
        ]
        for sample in samples {
            modelContext?.insert(sample)
        }
        saveAndRefresh()
    }

    private func seedVendors() {
        let vendorList: [VendorModel] = [
            VendorModel(
                name: "John's Plumbing", trade: .plumber,
                phoneNumber: "(555) 881-3042", email: "john@johnsplumbing.com",
                rating: 5, isAvailable: true,
                notes: "Reliable 24/7 emergency service. Responds within 1 hour.",
                typicalResponseHours: 1,
                nextAvailableSlot: Calendar.current.date(byAdding: .day, value: 0, to: Date())?.addingTimeInterval(3600)
            ),
            VendorModel(
                name: "QuickFix Drain", trade: .plumber,
                phoneNumber: "(555) 881-7731", email: "info@quickfixdrain.com",
                rating: 4, isAvailable: true,
                notes: "Good for non-emergency jobs. Usually 2-hour response.",
                typicalResponseHours: 2,
                nextAvailableSlot: Calendar.current.date(byAdding: .day, value: 1, to: Date())
            ),
            VendorModel(
                name: "CoolAir HVAC", trade: .hvac,
                phoneNumber: "(555) 881-5519", email: "service@coolairhvac.com",
                rating: 5, isAvailable: true,
                notes: "Premium HVAC service. Certified for all major brands. Emergency available.",
                typicalResponseHours: 3,
                nextAvailableSlot: Calendar.current.date(byAdding: .day, value: 1, to: Date())
            ),
            VendorModel(
                name: "Sparky Electric", trade: .electrician,
                phoneNumber: "(555) 881-2289", email: "sparky@sparkyelectric.com",
                rating: 5, isAvailable: false,
                notes: "Master electrician. Fully licensed and insured. Booked this week.",
                typicalResponseHours: 48,
                nextAvailableSlot: Calendar.current.date(byAdding: .day, value: 5, to: Date())
            ),
            VendorModel(
                name: "AllFix Handyman", trade: .handyman,
                phoneNumber: "(555) 881-1407", email: "mike@allfixhandyman.com",
                rating: 4, isAvailable: true,
                notes: "General handyman. Can handle most non-specialized repairs. Next-day availability.",
                typicalResponseHours: 24,
                nextAvailableSlot: Calendar.current.date(byAdding: .day, value: 1, to: Date())
            ),
            VendorModel(
                name: "PestAway Control", trade: .pestControl,
                phoneNumber: "(555) 881-6600", email: "help@pestaway.com",
                rating: 4, isAvailable: true,
                notes: "Eco-friendly treatments. Licensed and insured.",
                typicalResponseHours: 24,
                nextAvailableSlot: Calendar.current.date(byAdding: .day, value: 2, to: Date())
            ),
            VendorModel(
                name: "LockMaster 24/7", trade: .locksmith,
                phoneNumber: "(555) 881-9932", email: "lockmaster@lockmaster.com",
                rating: 5, isAvailable: true,
                notes: "Emergency locksmith. 20-minute response in metro area.",
                typicalResponseHours: 1,
                nextAvailableSlot: Calendar.current.date(byAdding: .day, value: 0, to: Date())
            ),
            VendorModel(
                name: "Peak Roofing Co", trade: .roofer,
                phoneNumber: "(555) 881-4421", email: "info@peakroofing.com",
                rating: 4, isAvailable: true,
                notes: "Commercial and residential roofing. Free estimates.",
                typicalResponseHours: 48,
                nextAvailableSlot: Calendar.current.date(byAdding: .day, value: 3, to: Date())
            ),
        ]
        for vendor in vendorList {
            modelContext?.insert(vendor)
        }
        // Seed appointments for the sample tickets with vendors
        if let mayaTicket = tickets.first(where: { $0.tenantName == "Maya Chen" }) {
            let appt = AppointmentModel(
                ticketID: mayaTicket.id,
                vendorName: "John's Plumbing",
                vendorPhone: "(555) 881-3042",
                vendorTrade: .plumber,
                proposedDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                status: .proposed,
                tenantResponse: .pending
            )
            modelContext?.insert(appt)
        }
        if let andreTicket = tickets.first(where: { $0.tenantName == "Andre Wilson" }) {
            let appt = AppointmentModel(
                ticketID: andreTicket.id,
                vendorName: "CoolAir HVAC",
                vendorPhone: "(555) 881-5519",
                vendorTrade: .hvac,
                proposedDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())?.addingTimeInterval(3600) ?? Date(),
                status: .proposed,
                tenantResponse: .pending
            )
            modelContext?.insert(appt)
        }
        saveAndRefresh()
    }
}
