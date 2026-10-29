//
//  LedgerScreen.swift
//  transaction
//
//  Created by Lzl on 2026/10/2.
//

import Combine
import SwiftUI

final class LedgerScreen: ObservableObject {
    @Published var tab = 0
    @Published var path: [Page] = []
    @Published var dashScope = LedgerScope.mine
    @Published var dashMode = PeriodMode.month
    @Published var dashFrom = LedgerDay.monthStart()
    @Published var dashTo = LedgerDay.today()
    @Published var txScope = LedgerScope.mine
    /// Account pages count every movement, household ones included.
    @Published var txUnscoped = false
    @Published var txMode = PeriodMode.month
    @Published var txFrom = LedgerDay.monthStart()
    @Published var txTo = LedgerDay.today()
    @Published var search = ""
    @Published var status = "all"
    @Published var txDirection = "all"
    @Published var accountFocus: String?
    @Published var category: String?
    @Published var showCalendar = false
    @Published var calendarDay: String?
    @Published var accountId: String?
    @Published var windowIndex = 1
    @Published var worthSpan = WorthSpan.month
    /// "", "out", "in", or "other". Set when a stats row opens the list.
    @Published var feedKind = ""

    var windowDays: Int { BookMath.windowDays[min(max(windowIndex, 0), 1)] }

    func open(_ page: Page) {
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
        txTo = min(to, LedgerDay.today())
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
        txTo = min(to, LedgerDay.today())
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
        txFrom = BookMath.windowStart(days: windowDays)
        txTo = LedgerDay.today()
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
