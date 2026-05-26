//
//  AppointmentModel.swift
//  RentGuard
//
//  Repair appointments linked to tenant tickets
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class AppointmentModel {
    var id: UUID
    var ticketID: UUID
    var vendorName: String
    var vendorPhone: String
    var vendorTradeRaw: String
    var proposedDate: Date
    var statusRaw: String
    var tenantResponseRaw: String
    var tenantReplyMessage: String
    var notes: String
    var createdAt: Date
    var confirmedAt: Date?

    init(
        id: UUID = UUID(),
        ticketID: UUID,
        vendorName: String,
        vendorPhone: String = "",
        vendorTrade: VendorTrade = .handyman,
        proposedDate: Date,
        status: AppointmentStatus = .proposed,
        tenantResponse: TenantResponse = .pending,
        tenantReplyMessage: String = "",
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.ticketID = ticketID
        self.vendorName = vendorName
        self.vendorPhone = vendorPhone
        self.vendorTradeRaw = vendorTrade.rawValue
        self.proposedDate = proposedDate
        self.statusRaw = status.rawValue
        self.tenantResponseRaw = tenantResponse.rawValue
        self.tenantReplyMessage = tenantReplyMessage
        self.notes = notes
        self.createdAt = createdAt
        self.confirmedAt = nil
    }
}

extension AppointmentModel {
    var status: AppointmentStatus {
        get { AppointmentStatus(rawValue: statusRaw) ?? .proposed }
        set { statusRaw = newValue.rawValue }
    }

    var tenantResponse: TenantResponse {
        get { TenantResponse(rawValue: tenantResponseRaw) ?? .pending }
        set { tenantResponseRaw = newValue.rawValue }
    }

    var vendorTrade: VendorTrade {
        VendorTrade(rawValue: vendorTradeRaw) ?? .handyman
    }

    var formattedDate: String {
        proposedDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour(.defaultDigits(amPM: .abbreviated)).minute(.twoDigits))
    }

    var isUpcoming: Bool {
        proposedDate > Date()
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(proposedDate)
    }

    var relativeTime: String {
        let interval = proposedDate.timeIntervalSince(Date())
        if abs(interval) < 3600 { return "soon" }
        if interval > 0 {
            let hours = Int(interval / 3600)
            if hours < 24 { return "in \(hours)h" }
            return "in \(hours / 24)d"
        }
        return proposedDate.formatted(.relative(presentation: .named))
    }
}

enum AppointmentStatus: String, CaseIterable, Codable {
    case proposed = "Proposed"
    case confirmed = "Confirmed"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var iconName: String {
        switch self {
        case .proposed: "clock.badge.questionmark"
        case .confirmed: "calendar.badge.checkmark"
        case .inProgress: "hammer.fill"
        case .completed: "checkmark.seal.fill"
        case .cancelled: "xmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .proposed: Color(red: 0.96, green: 0.73, blue: 0.29)
        case .confirmed: Color(red: 0.18, green: 0.82, blue: 0.78)
        case .inProgress: Color(red: 0.40, green: 0.55, blue: 0.90)
        case .completed: Color(red: 0.31, green: 0.82, blue: 0.37)
        case .cancelled: Color(red: 0.60, green: 0.60, blue: 0.65)
        }
    }
}

enum TenantResponse: String, Codable {
    case accepted = "Accepted"
    case declined = "Declined"
    case pending = "Pending"

    var iconName: String {
        switch self {
        case .accepted: "checkmark.bubble.fill"
        case .declined: "xmark.bubble.fill"
        case .pending: "ellipsis.bubble.fill"
        }
    }

    var tint: Color {
        switch self {
        case .accepted: Color(red: 0.31, green: 0.82, blue: 0.37)
        case .declined: Color(red: 1.0, green: 0.42, blue: 0.26)
        case .pending: Color(red: 0.57, green: 0.66, blue: 0.78)
        }
    }
}
