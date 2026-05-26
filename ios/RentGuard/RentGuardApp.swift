//
//  RentGuardApp.swift
//  RentGuard
//
//  App entry point with SwiftData persistence
//

import SwiftUI
import SwiftData

@main
struct RentGuardApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TenantTicketModel.self,
            VendorModel.self,
            AppointmentModel.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
