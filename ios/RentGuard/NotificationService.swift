//
//  NotificationService.swift
//  RentGuard
//
//  Local notification delivery for emergency tickets and reminders
//

import Foundation
import UserNotifications
import SwiftUI

@Observable
final class NotificationService {
    private var isAuthorized = false

    init() {
        requestAuthorization()
    }

    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            self.isAuthorized = granted
        }
    }

    /// Send a local notification for a new emergency-priority ticket
    func notifyEmergencyTicket(_ ticket: TenantTicketModel) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "🚨 Emergency: \(ticket.category.rawValue)"
        content.body = "\(ticket.tenantName) (\(ticket.unit)): \(ticket.message)"
        content.sound = .defaultCritical
        content.badge = 1
        content.userInfo = [
            "ticketID": ticket.id.uuidString,
            "priority": ticket.priority,
            "category": ticket.categoryRaw
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "emergency-\(ticket.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Notification failed: \(error)")
            }
        }
    }

    /// Send a reminder for a follow-up due
    func notifyFollowUp(ticket: TenantTicketModel, inHours hours: Int) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Follow-up: \(ticket.tenantName)"
        content.body = "\(ticket.unit) — \(hours)h follow-up due. Tap to review."
        content.sound = .default
        content.userInfo = ["ticketID": ticket.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(hours * 3600),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "followup-\(ticket.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Cancel all pending notifications for a ticket
    func cancelNotifications(for ticketID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                "emergency-\(ticketID.uuidString)",
                "followup-\(ticketID.uuidString)"
            ]
        )
    }
}
