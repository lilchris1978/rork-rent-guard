//
//  LandlordProfile.swift
//  RentGuard
//
//  Persistent landlord profile and property models
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Landlord Profile

@Model
final class LandlordProfileModel {
    var id: UUID
    var name: String
    var email: String
    var phoneNumber: String
    var companyName: String

    init(
        id: UUID = UUID(),
        name: String = "",
        email: String = "",
        phoneNumber: String = "",
        companyName: String = ""
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.companyName = companyName
    }

    var hasCompletedSetup: Bool {
        !name.isEmpty && !email.isEmpty
    }

    var initials: String {
        let components = name.split(separator: " ").prefix(2)
        return components.compactMap { $0.first }.map(String.init).joined()
    }
}

// MARK: - Property

@Model
final class PropertyModel {
    var id: UUID
    var name: String
    var address: String
    var city: String
    var state: String
    var zipCode: String
    var unitCount: Int
    var notes: String

    init(
        id: UUID = UUID(),
        name: String = "",
        address: String = "",
        city: String = "",
        state: String = "",
        zipCode: String = "",
        unitCount: Int = 0,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.unitCount = unitCount
        self.notes = notes
    }

    var fullAddress: String {
        [address, city, state, zipCode]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    var isEmpty: Bool {
        name.isEmpty && address.isEmpty
    }

    var totalUnitsFormatted: String {
        unitCount == 1 ? "1 unit" : "\(unitCount) units"
    }
}
