//
//  AIWorkflowService.swift
//  RentGuard
//
//  Simulates the AI pipeline: SMS → categorize → find vendor → schedule → auto-reply
//  In production this would call OpenAI GPT-4o-mini via the Rork proxy.
//

import Foundation

/// Represents a single step in the AI workflow timeline shown in the ticket detail
struct WorkflowStep: Identifiable, Equatable {
    let id: UUID
    let iconName: String
    let title: String
    let detail: String
    let timestamp: Date
    let tint: AppColor
    let isComplete: Bool
    let isLast: Bool

    init(
        id: UUID = UUID(),
        iconName: String,
        title: String,
        detail: String,
        timestamp: Date = Date(),
        tint: AppColor = .teal,
        isComplete: Bool = true,
        isLast: Bool = false
    ) {
        self.id = id
        self.iconName = iconName
        self.title = title
        self.detail = detail
        self.timestamp = timestamp
        self.tint = tint
        self.isComplete = isComplete
        self.isLast = isLast
    }
}

enum AppColor {
    case teal, orange, yellow, blue, green, red, purple, gray

    var swiftUIColor: Color {
        switch self {
        case .teal: Color(red: 0.18, green: 0.82, blue: 0.78)
        case .orange: Color(red: 1.0, green: 0.42, blue: 0.26)
        case .yellow: Color(red: 0.96, green: 0.73, blue: 0.29)
        case .blue: Color(red: 0.12, green: 0.56, blue: 0.98)
        case .green: Color(red: 0.31, green: 0.82, blue: 0.37)
        case .red: Color(red: 1.0, green: 0.42, blue: 0.26)
        case .purple: Color(red: 0.80, green: 0.35, blue: 0.85)
        case .gray: Color(red: 0.57, green: 0.66, blue: 0.78)
        }
    }
}

import SwiftUI

@Observable @MainActor
final class AIWorkflowService {
    /// Simulates the full AI triage of an incoming tenant SMS.
    /// Returns the recommended category, priority, and a human-readable explanation.
    func triage(message: String) -> (TicketCategory, Int, String) {
        let lowercased = message.lowercased()

        // Emergency detection
        let emergencyKeywords = [
            "flood", "gas leak", "fire", "smoke", "carbon monoxide",
            "no heat", "freezing", "burst pipe", "sewage", "ceiling collapse",
            "structural", "no power", "exposed wire", "sparking"
        ]
        let isEmergency = emergencyKeywords.contains { lowercased.contains($0) }
            || (lowercased.contains("water") && lowercased.contains("pouring"))
            || (lowercased.contains("leak") && lowercased.contains("ceiling"))
            || lowercased.contains("gas smell")

        if isEmergency {
            return (.emergency, 1, "Emergency detected — keyword match: \(extractKeywords(from: lowercased, candidates: emergencyKeywords).joined(separator: ", ")). Immediate dispatch required.")
        }

        // Water/maintenance urgency
        if lowercased.contains("water") || lowercased.contains("leak") || lowercased.contains("drip")
            || lowercased.contains("flood") || lowercased.contains("toilet") {
            return (.emergency, 1, "Water-related issue detected. Potential for property damage. Treat as priority 1.")
        }

        // HVAC no-AC/heat
        if (lowercased.contains("ac") || lowercased.contains("air condition") || lowercased.contains("heat"))
            && (lowercased.contains("not working") || lowercased.contains("stopped") || lowercased.contains("broken")) {
            return (.maintenance, 2, "HVAC failure detected. Weather-sensitive maintenance. Priority 2.")
        }

        // General maintenance
        let maintenanceKeywords = [
            "broken", "fix", "repair", "replace", "not working",
            "stopped", "damage", "crack", "hole", "mold", "pest",
            "appliance", "lock", "door", "window", "roof"
        ]
        if maintenanceKeywords.contains(where: { lowercased.contains($0) }) {
            return (.maintenance, 2, "Maintenance request detected. Non-emergency repair. Priority 2.")
        }

        // Payment
        if lowercased.contains("pay") || lowercased.contains("rent") || lowercased.contains("due")
            || lowercased.contains("late") || lowercased.contains("invoice") {
            return (.payment, 3, "Payment-related inquiry. Standard priority.")
        }

        return (.general, 4, "General inquiry. Low priority.")
    }

    /// Finds the best matching vendor from the directory for the given issue.
    func findVendor(for category: TicketCategory, message: String, vendors: [VendorModel]) -> VendorModel? {
        let neededTrade = VendorTrade.forCategory(category, message: message)

        // Prefer available vendors of the exact trade
        let exactMatches = vendors.filter { $0.trade == neededTrade }
        if let best = exactMatches.filter({ $0.isAvailableNow }).sorted(by: { $0.rating > $1.rating }).first {
            return best
        }
        if let fallback = exactMatches.sorted(by: { $0.rating > $1.rating }).first {
            return fallback
        }

        // Fallback to any available handyman
        let handymen = vendors.filter { $0.trade == .handyman && $0.isAvailableNow }
        if let best = handymen.sorted(by: { $0.rating > $1.rating }).first {
            return best
        }

        // Last resort: any available vendor
        return vendors.filter { $0.isAvailableNow }.sorted(by: { $0.rating > $1.rating }).first
    }

    /// Suggests the next reasonable appointment window.
    func suggestAppointment(vendor: VendorModel? = nil) -> Date {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)

        // If before 2pm, suggest tomorrow morning. If after 2pm, suggest day-after-tomorrow morning.
        var suggested = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        suggested = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: suggested) ?? suggested

        if hour >= 14 {
            suggested = calendar.date(byAdding: .day, value: 1, to: suggested) ?? suggested
        }

        // Skip weekends
        while calendar.isDateInWeekend(suggested) {
            suggested = calendar.date(byAdding: .day, value: 1, to: suggested) ?? suggested
        }

        // Use vendor's next available slot if provided
        if let vendorSlot = vendor?.nextAvailableSlot, vendorSlot > suggested {
            return vendorSlot
        }

        return suggested
    }

    /// Generates the auto-reply SMS text that would be sent back to the tenant.
    func generateReply(
        tenantName: String,
        issue: String,
        vendorName: String,
        vendorPhone: String,
        appointmentDate: Date
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        let day = formatter.string(from: appointmentDate)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let time = timeFormatter.string(from: appointmentDate)

        return "Hi \(tenantName), thanks for reporting this. I've categorized your issue (\(issue.prefix(40))) as a priority. I'm sending \(vendorName) (\(vendorPhone)) to your unit on \(day) between \(time) — does that work? Reply Y to confirm or R to reschedule."
    }

    /// Builds the workflow timeline steps for display in the ticket detail.
    func buildTimeline(
        for ticket: TenantTicketModel,
        vendor: VendorModel?,
        appointment: AppointmentModel?
    ) -> [WorkflowStep] {
        var steps: [WorkflowStep] = []

        // Step 1: SMS Received
        steps.append(WorkflowStep(
            iconName: "message.fill",
            title: "SMS Received",
            detail: ticket.message,
            timestamp: ticket.createdAt,
            tint: .gray,
            isComplete: true
        ))

        // Step 2: AI Triage
        let categoryLabel = ticket.category.rawValue
        steps.append(WorkflowStep(
            iconName: ticket.category.iconName,
            title: "AI Categorized as \(categoryLabel)",
            detail: "Priority P\(ticket.priority) · Confidence \(Int(ticket.aiConfidence * 100))%",
            timestamp: ticket.createdAt.addingTimeInterval(8),
            tint: ticket.category == .emergency ? .red : ticket.category == .maintenance ? .teal : .yellow,
            isComplete: true
        ))

        // Step 3: Vendor Match
        if let vendor {
            steps.append(WorkflowStep(
                iconName: vendor.trade.iconName,
                title: "Vendor Matched: \(vendor.name)",
                detail: "\(vendor.trade.rawValue) · \(vendor.phoneNumber) · \(vendor.ratingDisplay)",
                timestamp: ticket.createdAt.addingTimeInterval(15),
                tint: .blue,
                isComplete: true
            ))
        } else if ticket.status == .vendor || ticket.status == .escalated {
            steps.append(WorkflowStep(
                iconName: "person.fill.questionmark",
                title: "Searching for a \(VendorTrade.forCategory(ticket.category, message: ticket.message).rawValue)...",
                detail: "No available vendor found. Tap to assign one manually.",
                timestamp: ticket.createdAt.addingTimeInterval(15),
                tint: .orange,
                isComplete: false,
                isLast: true
            ))
            return steps
        }

        // Step 4: Appointment
        if let appointment {
            let isConfirmed = appointment.status == .confirmed
            let stepTitle = isConfirmed
                ? "Appointment Confirmed"
                : "Appointment Proposed"
            let stepDetail = "\(appointment.formattedDate) · \(appointment.vendorName)"
            steps.append(WorkflowStep(
                iconName: isConfirmed ? "calendar.badge.checkmark" : "calendar.badge.clock",
                title: stepTitle,
                detail: stepDetail,
                timestamp: appointment.createdAt,
                tint: isConfirmed ? .green : .yellow,
                isComplete: isConfirmed
            ))

            // Step 5: Auto-reply sent
            if !ticket.aiReply.isEmpty {
                steps.append(WorkflowStep(
                    iconName: "bubble.left.and.text.bubble.right.fill",
                    title: "Auto-Reply Sent",
                    detail: ticket.aiReply,
                    timestamp: ticket.createdAt.addingTimeInterval(25),
                    tint: .teal,
                    isComplete: true
                ))
            }

            // Step 6: Tenant response status
            if appointment.tenantResponse == .pending {
                steps.append(WorkflowStep(
                    iconName: "clock.badge.questionmark",
                    title: "Awaiting Tenant Confirmation",
                    detail: "Tenant has not yet responded to the proposed time.",
                    timestamp: appointment.createdAt,
                    tint: .orange,
                    isComplete: false,
                    isLast: true
                ))
            } else if appointment.tenantResponse == .accepted {
                steps.append(WorkflowStep(
                    iconName: "checkmark.bubble.fill",
                    title: "Tenant Confirmed",
                    detail: appointment.tenantReplyMessage.isEmpty
                        ? "Tenant accepted the appointment."
                        : appointment.tenantReplyMessage,
                    timestamp: appointment.confirmedAt ?? appointment.createdAt,
                    tint: .green,
                    isComplete: true,
                    isLast: true
                ))
            } else if appointment.tenantResponse == .declined {
                steps.append(WorkflowStep(
                    iconName: "xmark.bubble.fill",
                    title: "Tenant Declined",
                    detail: appointment.tenantReplyMessage.isEmpty
                        ? "Tenant declined. Propose a new time."
                        : appointment.tenantReplyMessage,
                    timestamp: Date(),
                    tint: .red,
                    isComplete: true,
                    isLast: true
                ))
            }
        } else {
            steps.append(WorkflowStep(
                iconName: "calendar.badge.plus",
                title: "Schedule Appointment",
                detail: "Tap to propose a repair time for the tenant.",
                timestamp: Date(),
                tint: .yellow,
                isComplete: false,
                isLast: true
            ))
        }

        return steps
    }

    private func extractKeywords(from text: String, candidates: [String]) -> [String] {
        candidates.filter { text.contains($0) }
    }
}
