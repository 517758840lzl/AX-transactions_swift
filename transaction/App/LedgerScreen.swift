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

    var windowDays: Int { BookMath.windowDays[min(max(windowIndex, 0), 1)] }

    func open(_ page: Page) {
        path.append(page)
    }

    func close() {
        if !path.isEmpty { path.removeLast() }
    }

    func openRange(account id: String, from: String, to: String) {
        accountId = id
        txMode = .range
        txFrom = from
        txTo = min(to, LedgerDay.today())
        category = nil
        status = "all"
        txDirection = "all"
        search = ""
        showCalendar = false
        tab = 1
        path = []
    }

    func openAccountFeed(id: String) {
        accountId = id
        txMode = .range
        txFrom = BookMath.windowStart(days: windowDays)
        txTo = LedgerDay.today()
        category = nil
        status = "all"
        txDirection = "all"
        search = ""
        showCalendar = false
        tab = 1
        path = []
    }
}
