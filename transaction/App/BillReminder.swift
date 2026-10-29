//
//  BillReminder.swift
//  transaction
//
//  Created by Lzl on 2026/10/28.
//

import Foundation
import UserNotifications

extension Notification.Name {
    static let billReminderOpened = Notification.Name("billReminderOpened")
}

struct BillPayload: Sendable {
    var identifier: String
    var accountID: String
    var fire: Date
    var body: String
}

final class BillReminder: NSObject, UNUserNotificationCenterDelegate {
    static let shared = BillReminder()

    private var pendingAccountID: String?
    private var handled: Set<String> = []
    private var generation = 0

    func refresh(book: Book) {
        generation += 1
        let token = generation
        let payloads = Self.payloads(book: book)
        if payloads.isEmpty {
            clear(token: token)
            return
        }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            let status = settings.authorizationStatus
            Task { @MainActor in
                guard token == self.generation else { return }
                self.apply(status: status, payloads: payloads, token: token)
            }
        }
    }

    func takePendingAccountID() -> String? {
        let id = pendingAccountID
        pendingAccountID = nil
        return id
    }

    func remember(_ response: UNNotificationResponse) {
        let requestID = response.notification.request.identifier
        guard requestID.hasPrefix("bill-"),
              let accountID = response.notification.request.content.userInfo["accountId"] as? String,
              handled.insert(requestID).inserted else { return }
        pendingAccountID = accountID
        NotificationCenter.default.post(name: .billReminderOpened, object: accountID)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            BillReminder.shared.remember(response)
            completionHandler()
        }
    }

    private static func payloads(book: Book) -> [BillPayload] {
        let copy = LedgerCopy.resolve(book.locale)
        return BillPlan.notices(accounts: book.accounts, entries: book.entries).map { notice in
            let amount = book.hideAmounts ? "***" : LedgerMoney.text(notice.amount, mark: book.mark)
            let body = notice.kind == .statement
                ? copy.billStatement(notice.name, amount: amount)
                : copy.billDue(notice.name, amount: amount)
            return BillPayload(
                identifier: "bill-\(notice.accountID)-\(notice.kind.rawValue)",
                accountID: notice.accountID,
                fire: notice.fire,
                body: body
            )
        }
    }

    private func apply(status: UNAuthorizationStatus, payloads: [BillPayload], token: Int) {
        let center = UNUserNotificationCenter.current()
        switch status {
        case .notDetermined:
            center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                Task { @MainActor in
                    guard token == self.generation else { return }
                    if granted { self.write(payloads, token: token) }
                    else { self.clear(token: token) }
                }
            }
        case .authorized, .provisional, .ephemeral:
            write(payloads, token: token)
        default:
            clear(token: token)
        }
    }

    private func write(_ payloads: [BillPayload], token: Int) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { pending in
            let stale = pending.map(\.identifier).filter { $0.hasPrefix("bill-") }
            Task { @MainActor in
                guard token == self.generation else { return }
                let keep = Set(payloads.map(\.identifier))
                center.removePendingNotificationRequests(withIdentifiers: stale.filter { !keep.contains($0) })
                let calendar = Calendar.current
                for payload in payloads {
                    let content = UNMutableNotificationContent()
                    content.body = payload.body
                    content.sound = .default
                    content.userInfo = ["accountId": payload.accountID]
                    var parts = calendar.dateComponents([.year, .month, .day], from: payload.fire)
                    parts.hour = BillPlan.hour
                    parts.minute = 0
                    let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
                    center.add(UNNotificationRequest(identifier: payload.identifier, content: content, trigger: trigger))
                }
            }
        }
    }

    private func clear(token: Int) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { pending in
            let ids = pending.map(\.identifier).filter { $0.hasPrefix("bill-") }
            Task { @MainActor in
                guard token == self.generation else { return }
                center.removePendingNotificationRequests(withIdentifiers: ids)
            }
        }
    }
}
