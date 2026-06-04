//
//  TenantModel.swift
//  RentGuard
//
//  Tenant directory — manual entry, contacts import, CSV import
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class TenantModel {
    var id: UUID
    var name: String
    var phoneNumber: String
    var email: String
    var unit: String
    var propertyName: String
    var leaseStart: Date?
    var leaseEnd: Date?
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        phoneNumber: String = "",
        email: String = "",
        unit: String = "",
        propertyName: String = "",
        leaseStart: Date? = nil,
        leaseEnd: Date? = nil,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.unit = unit
        self.propertyName = propertyName
        self.leaseStart = leaseStart
        self.leaseEnd = leaseEnd
        self.notes = notes
        self.createdAt = createdAt
    }

    var initials: String {
        let components = name.split(separator: " ").prefix(2)
        return components.compactMap { $0.first }.map(String.init).joined()
    }

    var hasLease: Bool {
        leaseStart != nil && leaseEnd != nil
    }

    var leaseActive: Bool {
        guard let end = leaseEnd else { return false }
        return Date() < end
    }

    var displayUnit: String {
        if unit.isEmpty && propertyName.isEmpty { return "No unit assigned" }
        if propertyName.isEmpty { return unit }
        if unit.isEmpty { return propertyName }
        return "\(propertyName) — \(unit)"
    }
}
