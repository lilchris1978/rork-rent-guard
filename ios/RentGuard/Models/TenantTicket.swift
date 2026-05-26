//
//  TenantTicket.swift
//  RentGuard
//
//  Models for tenant communication tickets
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class TenantTicketModel {
    var id: UUID
    var tenantName: String
    var unit: String
    var phoneNumber: String
    var categoryRaw: String
    var message: String
    var createdAt: Date
    var priority: Int
    var statusRaw: String
    var hasPhoto: Bool
    var nextStep: String
    var resolvedAt: Date?
    var followUpAt: Date?
    var escalationCount: Int
    var notes: String
    var aiConfidence: Double

    // AI workflow fields
    var assignedVendorName: String
    var assignedVendorPhone: String
    var assignedVendorTradeRaw: String
    var aiReply: String

    init(
        id: UUID = UUID(),
        tenantName: String,
        unit: String,
        phoneNumber: String = "",
        category: TicketCategory,
        message: String,
        createdAt: Date = Date(),
        priority: Int = 3,
        status: TicketStatus = .open,
        hasPhoto: Bool = false,
        nextStep: String = "",
        followUpAt: Date? = nil,
        notes: String = "",
        aiConfidence: Double = 0.95,
        assignedVendorName: String = "",
        assignedVendorPhone: String = "",
        assignedVendorTrade: VendorTrade = .handyman,
        aiReply: String = ""
    ) {
        self.id = id
        self.tenantName = tenantName
        self.unit = unit
        self.phoneNumber = phoneNumber
        self.categoryRaw = category.rawValue
        self.message = message
        self.createdAt = createdAt
        self.priority = priority
        self.statusRaw = status.rawValue
        self.hasPhoto = hasPhoto
        self.nextStep = nextStep
        self.resolvedAt = nil
        self.followUpAt = followUpAt
        self.escalationCount = 0
        self.notes = notes
        self.aiConfidence = aiConfidence
        self.assignedVendorName = assignedVendorName
        self.assignedVendorPhone = assignedVendorPhone
        self.assignedVendorTradeRaw = assignedVendorTrade.rawValue
        self.aiReply = aiReply
    }
}

extension TenantTicketModel {
    var category: TicketCategory {
        TicketCategory(rawValue: categoryRaw) ?? .general
    }

    var status: TicketStatus {
        get { TicketStatus(rawValue: statusRaw) ?? .open }
        set { statusRaw = newValue.rawValue }
    }

    var relativeTime: String {
        let interval = Date().timeIntervalSince(createdAt)
        switch interval {
        case ..<60: return "just now"
        case ..<3600: return "\(Int(interval / 60))m"
        case ..<86400: return "\(Int(interval / 3600))h"
        case ..<604800: return "\(Int(interval / 86400))d"
        default: return createdAt.formatted(.relative(presentation: .named))
        }
    }

    var isOverdue: Bool {
        guard let followUpAt, status != .resolved else { return false }
        return Date() > followUpAt
    }

    var assignedVendorTrade: VendorTrade {
        VendorTrade(rawValue: assignedVendorTradeRaw) ?? .handyman
    }

    var hasVendorAssigned: Bool {
        !assignedVendorName.isEmpty
    }

    var hasAppointmentScheduled: Bool {
        status == .vendor || status == .review
    }
}

enum TicketCategory: String, CaseIterable, Codable {
    case emergency = "Emergency"
    case maintenance = "Maintenance"
    case payment = "Payment"
    case general = "General"

    var iconName: String {
        switch self {
        case .emergency: "bolt.shield.fill"
        case .maintenance: "wrench.and.screwdriver.fill"
        case .payment: "creditcard.fill"
        case .general: "bubble.left.and.bubble.right.fill"
        }
    }

    var tint: Color {
        switch self {
        case .emergency: Color(red: 1.0, green: 0.42, blue: 0.26)
        case .maintenance: Color(red: 0.18, green: 0.82, blue: 0.78)
        case .payment: Color(red: 0.96, green: 0.73, blue: 0.29)
        case .general: Color(red: 0.57, green: 0.66, blue: 0.78)
        }
    }
}

enum TicketStatus: String, CaseIterable, Codable {
    case open = "Open"
    case vendor = "Vendor"
    case review = "Review"
    case answered = "Answered"
    case escalated = "Escalated"
    case resolved = "Resolved"

    var tint: Color {
        switch self {
        case .open: Color(red: 1.0, green: 0.42, blue: 0.26)
        case .vendor: Color(red: 0.18, green: 0.82, blue: 0.78)
        case .review: Color(red: 0.96, green: 0.73, blue: 0.29)
        case .answered: Color(red: 0.57, green: 0.66, blue: 0.78)
        case .escalated: Color(red: 0.80, green: 0.35, blue: 0.85)
        case .resolved: Color(red: 0.31, green: 0.82, blue: 0.37)
        }
    }
}
