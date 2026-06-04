//
//  RentGuardApp.swift
//  RentGuard
//
//  App entry point — AuthManager + SwiftData + Notification delegate
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct RentGuardApp: App {
    @State private var authManager = AuthManager()
    @State private var notificationService = NotificationService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TenantTicketModel.self,
            VendorModel.self,
            AppointmentModel.self,
            LandlordProfileModel.self,
            PropertyModel.self,
            TenantModel.self,
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

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .environment(notificationService)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Notification Delegate

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        if let ticketIDString = userInfo["ticketID"] as? String {
            NotificationCenter.default.post(
                name: .openTicketNotification,
                object: nil,
                userInfo: ["ticketID": ticketIDString]
            )
        }
    }
}

extension Notification.Name {
    static let openTicketNotification = Notification.Name("openTicketNotification")
}
