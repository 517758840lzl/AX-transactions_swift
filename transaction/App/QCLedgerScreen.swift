//
//  QCLedgerScreen.swift
//  transaction
//
//  Created by Lzl on 2026/10/2.
//

import Combine
import SwiftUI

final class QCLedgerScreen: ObservableObject {
    @Published var tab = 0
    @Published var path: [QCPage] = []
    @Published var dashScope = QCLedgerScope.mine
    @Published var dashMode = QCPeriodMode.month
    @Published var dashFrom = QCLedgerDay.monthStart()
    @Published var dashTo = QCLedgerDay.today()
    @Published var txScope = QCLedgerScope.mine
    /// Account pages count every movement, household ones included.
    @Published var txUnscoped = false
    @Published var txMode = QCPeriodMode.month
    @Published var txFrom = QCLedgerDay.monthStart()
    @Published var txTo = QCLedgerDay.today()
    @Published var search = ""
    @Published var status = "all"
    @Published var txDirection = "all"
    @Published var accountFocus: String?
    @Published var category: String?
    @Published var showCalendar = false
    @Published var calendarDay: String?
    @Published var accountId: String?
    @Published var windowIndex = 1
    @Published var worthSpan = QCWorthSpan.month
    /// "", "out", "in", or "other". Set when a stats row opens the list.
    @Published var feedKind = ""
    /// Overview pills: "out", "in", or "other". A new entry follows this.
    @Published var statsKind = "out"
    /// Kind used when a new idea page opens.
    var sparkDraftKind = QCSparkKind.idea.rawValue
    /// Words carried from the inspiration tab into the full note list.
    var sparkLookup = ""
    @Published var entryDirection = QCDirection.out
    @Published var categoryPickSlot = ""
    @Published var categoryPickName = ""

    var windowDays: Int { QCBookMath.windowDays[min(max(windowIndex, 0), 1)] }

    func openNewRecord(store: QCBookStore) {
        if statsKind == "other" {
            let own = store.book.accounts.filter { !$0.id.hasPrefix("sample-") }
            if own.count < 2 {
                open(.accountForm(id: nil, chooseKind: true))
            } else {
                open(.transfer)
            }
            return
        }
        entryDirection = statsKind == "in" ? .income : .out
        open(.entry(id: nil))
    }

    func open(_ page: QCPage) {
        withAnimation(Self.pageSlide) {
            path.append(page)
        }
    }

    func close(animated: Bool = true) {
        guard !path.isEmpty else { return }
        let update = { _ = self.path.removeLast() }
        if animated {
            withAnimation(Self.pageSlide) { update() }
        } else {
            var step = Transaction()
            step.disablesAnimations = true
            withTransaction(step) { update() }
        }
    }

    func selectTab(_ index: Int) {
        feedKind = ""
        txUnscoped = false
        withAnimation(Self.tabFade) {
            tab = index
        }
    }

    /// Leave this page and land on a tab.
    func reveal(tab index: Int) {
        withAnimation(Self.pageSlide) {
            tab = index
            path.removeAll()
        }
    }

    static let pageSlide = Animation.timingCurve(0.22, 0.9, 0.28, 1, duration: 0.34)
    private static let tabFade = Animation.easeInOut(duration: 0.2)
    static let fold = Animation.timingCurve(0.22, 0.9, 0.28, 1, duration: 0.28)

    func openStats(from: String, to: String, kind: String, category: String?, title: String?) {
        txScope = dashScope
        txMode = .range
        txFrom = from
        txTo = min(to, QCLedgerDay.today())
        self.category = category
        search = title ?? ""
        status = "all"
        txDirection = "all"
        accountId = nil
        feedKind = kind
        txUnscoped = false
        showCalendar = false
        reveal(tab: 1)
    }

    func openRange(account id: String, from: String, to: String) {
        accountId = id
        txMode = .range
        txFrom = from
        txTo = min(to, QCLedgerDay.today())
        category = nil
        feedKind = ""
        status = "all"
        txDirection = "all"
        search = ""
        showCalendar = false
        txUnscoped = true
        reveal(tab: 1)
    }

    func openAccountFeed(id: String) {
        accountId = id
        txMode = .range
        txFrom = QCBookMath.windowStart(days: windowDays)
        txTo = QCLedgerDay.today()
        category = nil
        feedKind = ""
        status = "all"
        txDirection = "all"
        search = ""
        showCalendar = false
        txUnscoped = true
        reveal(tab: 1)
    }
}
