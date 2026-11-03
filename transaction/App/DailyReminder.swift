//
//  DailyReminder.swift
//  transaction
//

import Foundation
import UserNotifications

extension Notification.Name {
    static let dailyLogOpened = Notification.Name("dailyLogOpened")
    static let reminderAccessChanged = Notification.Name("reminderAccessChanged")
}

final class DailyReminder {
    static let shared = DailyReminder()
    static let identifier = "daily-log"

    private var generation = 0

    private init() {}

    func sync(_ book: Book, ask: Bool) {
        generation += 1
        let token = generation
        let center = UNUserNotificationCenter.current()
        guard book.dailyReminder else {
            center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
            notifyAccess()
            return
        }
        let hour = min(max(book.reminderHour, 0), 23)
        let minute = min(max(book.reminderMinute, 0), 59)
        let body = LedgerCopy.resolve(book.locale).reminderPing
        center.getNotificationSettings { settings in
            let status = settings.authorizationStatus
            Task { @MainActor in
                guard token == self.generation else { return }
                self.apply(status: status, ask: ask, hour: hour, minute: minute, body: body, token: token)
            }
        }
    }

    private func apply(status: UNAuthorizationStatus, ask: Bool, hour: Int, minute: Int, body: String, token: Int) {
        let center = UNUserNotificationCenter.current()
        switch status {
        case .notDetermined:
            guard ask else {
                notifyAccess()
                return
            }
            center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                Task { @MainActor in
                    guard token == self.generation else { return }
                    if granted { self.place(hour: hour, minute: minute, body: body) }
                    self.notifyAccess()
                }
            }
        case .authorized, .provisional, .ephemeral:
            place(hour: hour, minute: minute, body: body)
            notifyAccess()
        default:
            center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
            notifyAccess()
        }
    }

    private func place(hour: Int, minute: Int, body: String) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.body = body
        content.sound = .default
        var parts = DateComponents()
        parts.hour = hour
        parts.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
        let request = UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger)
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
        center.add(request)
    }

    private func notifyAccess() {
        NotificationCenter.default.post(name: .reminderAccessChanged, object: nil)
    }
}
