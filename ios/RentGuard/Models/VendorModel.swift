//
//  VendorModel.swift
//  RentGuard
//
//  Tradesperson directory for repair dispatch
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class VendorModel {
    var id: UUID
    var name: String
    var tradeRaw: String
    var phoneNumber: String
    var email: String
    var rating: Int
    var isAvailable: Bool
    var notes: String
    var typicalResponseHours: Int
    var nextAvailableSlot: Date?

    init(
        id: UUID = UUID(),
        name: String,
        trade: VendorTrade,
        phoneNumber: String,
        email: String = "",
        rating: Int = 4,
        isAvailable: Bool = true,
        notes: String = "",
        typicalResponseHours: Int = 24,
        nextAvailableSlot: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.tradeRaw = trade.rawValue
        self.phoneNumber = phoneNumber
        self.email = email
        self.rating = rating
        self.isAvailable = isAvailable
        self.notes = notes
        self.typicalResponseHours = typicalResponseHours
        self.nextAvailableSlot = nextAvailableSlot
    }
}

extension VendorModel {
    var trade: VendorTrade {
        VendorTrade(rawValue: tradeRaw) ?? .handyman
    }

    var ratingDisplay: String {
        String(repeating: "★", count: rating) + String(repeating: "☆", count: 5 - rating)
    }

    var isAvailableNow: Bool {
        isAvailable && (nextAvailableSlot ?? Date()) <= Date().addingTimeInterval(24 * 3600)
    }
}

enum VendorTrade: String, CaseIterable, Codable {
    case plumber = "Plumber"
    case electrician = "Electrician"
    case hvac = "HVAC"
    case handyman = "Handyman"
    case roofer = "Roofer"
    case painter = "Painter"
    case locksmith = "Locksmith"
    case applianceRepair = "Appliance Repair"
    case pestControl = "Pest Control"
    case cleaner = "Cleaner"
    case landscaper = "Landscaper"

    var iconName: String {
        switch self {
        case .plumber: "drop.fill"
        case .electrician: "bolt.fill"
        case .hvac: "fanblades.fill"
        case .handyman: "hammer.fill"
        case .roofer: "house.fill"
        case .painter: "paintbrush.fill"
        case .locksmith: "lock.fill"
        case .applianceRepair: "washer.fill"
        case .pestControl: "ant.fill"
        case .cleaner: "bubbles.and.sparkles.fill"
        case .landscaper: "leaf.fill"
        }
    }

    var tint: Color {
        switch self {
        case .plumber: Color(red: 0.12, green: 0.56, blue: 0.98)
        case .electrician: Color(red: 0.98, green: 0.73, blue: 0.12)
        case .hvac: Color(red: 0.18, green: 0.82, blue: 0.78)
        case .handyman: Color(red: 0.57, green: 0.47, blue: 0.35)
        case .roofer: Color(red: 0.65, green: 0.35, blue: 0.20)
        case .painter: Color(red: 0.80, green: 0.35, blue: 0.85)
        case .locksmith: Color(red: 0.55, green: 0.55, blue: 0.60)
        case .applianceRepair: Color(red: 0.40, green: 0.45, blue: 0.55)
        case .pestControl: Color(red: 0.85, green: 0.35, blue: 0.35)
        case .cleaner: Color(red: 0.30, green: 0.75, blue: 0.55)
        case .landscaper: Color(red: 0.25, green: 0.70, blue: 0.30)
        }
    }

    /// Maps ticket categories to the most likely vendor trade needed
    static func forCategory(_ category: TicketCategory, message: String) -> VendorTrade {
        let lowercased = message.lowercased()
        switch category {
        case .emergency, .maintenance:
            if lowercased.contains("water") || lowercased.contains("leak") || lowercased.contains("pipe")
                || lowercased.contains("toilet") || lowercased.contains("sink") || lowercased.contains("drain")
                || lowercased.contains("shower") || lowercased.contains("bath") || lowercased.contains("plumb") {
                return .plumber
            }
            if lowercased.contains("electric") || lowercased.contains("power") || lowercased.contains("outlet")
                || lowercased.contains("light") || lowercased.contains("breaker") || lowercased.contains("wire") {
                return .electrician
            }
            if lowercased.contains("ac") || lowercased.contains("air condition") || lowercased.contains("hvac")
                || lowercased.contains("heat") || lowercased.contains("cool") || lowercased.contains("furnace")
                || lowercased.contains("thermostat") || lowercased.contains("vent") {
                return .hvac
            }
            if lowercased.contains("roof") || lowercased.contains("ceiling") || lowercased.contains("leak") {
                return .roofer
            }
            if lowercased.contains("lock") || lowercased.contains("key") || lowercased.contains("door") {
                return .locksmith
            }
            if lowercased.contains("appliance") || lowercased.contains("fridge") || lowercased.contains("stove")
                || lowercased.contains("oven") || lowercased.contains("washer") || lowercased.contains("dryer")
                || lowercased.contains("dishwasher") {
                return .applianceRepair
            }
            if lowercased.contains("pest") || lowercased.contains("bug") || lowercased.contains("rat")
                || lowercased.contains("mouse") || lowercased.contains("roach") || lowercased.contains("ant") {
                return .pestControl
            }
            return .handyman
        case .payment, .general:
            return .handyman
        }
    }
}
