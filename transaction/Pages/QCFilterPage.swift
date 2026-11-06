//
//  QCFilterPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/14.
//

import SwiftUI

struct QCFilterFormView: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen
    var which: String
    @Environment(\.pageBack) private var pageBack
    @State private var scope = QCLedgerScope.mine
    @State private var mode = QCPeriodMode.month
    @State private var from = QCLedgerDay.monthStart()
    @State private var to = QCLedgerDay.today()
    @State private var ready = false

    var body: some View {
        let copy = store.copy
        QCFormPage(title: copy.filter, back: copy.back, place: "filter-\(which)") {
            QCPanelCard(title: copy.filterScope) {
                QCChoiceRow(labels: [copy.scopeMine, copy.scopeFamily], index: scope == .mine ? 0 : 1) { index in
                    scope = index == 0 ? .mine : .family
                }
            }
            QCPanelCard(title: copy.time) {
                QCChoiceRow(labels: [copy.today, copy.thisMonth, copy.customRange], index: modeIndex) { index in
                    withAnimation(QCLedgerScreen.fold) {
                        mode = index == 0 ? .today : (index == 1 ? .month : .range)
                    }
                }
                if mode == .range {
                    HStack(spacing: 8) {
                        QCDateField(copy: copy, iso: $from, label: copy.rangeStart)
                        Text(copy.rangeTo)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(QCPalette.ink)
                        QCDateField(copy: copy, iso: $to, label: copy.rangeEnd)
                    }
                    .padding(.top, 8)
                    .transition(.opacity)
                }
            }
            QCPillButton(title: copy.done) { pageBack() }
        }
        .onDisappear { if ready { apply() } }
        .onAppear {
            guard !ready else { return }
            ready = true
            if which == "dashboard" {
                scope = screen.dashScope
                mode = screen.dashMode
                from = screen.dashFrom
                to = screen.dashTo
            } else {
                scope = screen.txScope
                mode = screen.txMode
                from = screen.txFrom
                to = screen.txTo
            }
        }
    }

    private var modeIndex: Int {
        switch mode {
        case .today: return 0
        case .month: return 1
        case .range: return 2
        }
    }

    private func apply() {
        if which == "dashboard" {
            screen.dashScope = scope
            screen.dashMode = mode
            screen.dashFrom = from
            screen.dashTo = to
        } else {
            let changed = mode != screen.txMode || from != screen.txFrom || to != screen.txTo
            screen.txScope = scope
            screen.txMode = mode
            screen.txFrom = from
            screen.txTo = to
            if changed { screen.category = nil }
        }
    }
}
