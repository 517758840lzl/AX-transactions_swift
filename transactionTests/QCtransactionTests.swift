//
//  QCtransactionTests.swift
//  QCtransactionTests
//
//  Created by Lzl on 2026/9/29.
//

import XCTest
@testable import transaction

final class QCtransactionTests: XCTestCase {

    func testBillNoticeUsesTheClosedPeriod() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = try date("2026-10-20", hour: 10, calendar: calendar)
        let card = QCAccount(id: "visa", name: "Visa", opening: 0, kind: .card, countsInWorth: true, statementDay: 15, dueDay: 5)
        let entries = [
            row("old", "2026-09-20", 7, .out),
            row("closed", "2026-10-10", 100, .out),
            row("back", "2026-10-12", 20, .income),
            row("open", "2026-10-16", 40, .out),
        ]
        let notices = QCBillPlan.notices(accounts: [card], entries: entries, now: now, calendar: calendar)
        XCTAssertEqual(notices.map(\.kind), [.statement, .due])
        XCTAssertEqual(QCLedgerDay.iso(notices[0].fire, calendar: calendar), "2026-11-15")
        XCTAssertEqual(calendar.component(.hour, from: notices[0].fire), 9)
        XCTAssertEqual(notices[0].amount, 40, accuracy: 0.001)
        XCTAssertEqual(QCLedgerDay.iso(notices[1].fire, calendar: calendar), "2026-11-05")
        XCTAssertEqual(notices[1].amount, 87, accuracy: 0.001)
    }

    func testBillNoticeSkipsCardsWithoutASeparateDueDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = try date("2026-11-15", hour: 8, calendar: calendar)
        let sameDay = QCAccount(id: "a", name: "A", opening: 0, kind: .card, countsInWorth: true, statementDay: 15, dueDay: 15)
        let noDue = QCAccount(id: "b", name: "B", opening: 0, kind: .card, countsInWorth: true, statementDay: 15, dueDay: 0)
        let archived = QCAccount(id: "c", name: "C", opening: 0, kind: .card, countsInWorth: true, archived: true, statementDay: 15, dueDay: 5)
        let cash = QCAccount(id: "d", name: "D", opening: 0, kind: .cash, countsInWorth: true, statementDay: 15, dueDay: 5)
        let morning = QCBillPlan.notices(accounts: [sameDay], entries: [], now: now, calendar: calendar)
        XCTAssertEqual(morning.map(\.kind), [.statement])
        XCTAssertEqual(QCLedgerDay.iso(morning[0].fire, calendar: calendar), "2026-11-15")
        let later = try date("2026-11-15", hour: 9, calendar: calendar)
        let next = QCBillPlan.notices(accounts: [noDue], entries: [], now: later, calendar: calendar)
        XCTAssertEqual(QCLedgerDay.iso(next[0].fire, calendar: calendar), "2026-12-15")
        XCTAssertTrue(QCBillPlan.notices(accounts: [archived, cash], entries: [], now: now, calendar: calendar).isEmpty)
    }

    private func date(_ iso: String, hour: Int, calendar: Calendar) throws -> Date {
        let parts = iso.split(separator: "-").compactMap { Int($0) }
        let value = calendar.date(from: DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: parts[0], month: parts[1], day: parts[2], hour: hour))
        return try XCTUnwrap(value)
    }

    private func row(_ id: String, _ day: String, _ amount: Double, _ direction: QCDirection) -> QCEntry {
        QCEntry(
            id: id,
            title: id,
            amount: amount,
            direction: direction,
            category: "Dining",
            date: day,
            accountName: "Visa",
            accountId: "visa",
            checked: true,
            shared: false,
            countsInBudget: true,
            claim: .none
        )
    }
}
