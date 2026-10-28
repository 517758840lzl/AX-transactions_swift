//
//  FilterPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/14.
//

import Combine
import SwiftUI

struct FilterFormView: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
    var which: String
    @Environment(\.pageBack) private var pageBack
    @State private var scope = LedgerScope.mine
    @State private var mode = PeriodMode.month
    @State private var from = LedgerDay.monthStart()
    @State private var to = LedgerDay.today()
    @State private var ready = false

    var body: some View {
        let copy = store.copy
        FormPage(title: copy.filter, back: copy.back) {
            PanelCard(title: copy.filterScope) {
                ChoiceRow(labels: [copy.scopeMine, copy.scopeFamily], index: scope == .mine ? 0 : 1) { index in
                    scope = index == 0 ? .mine : .family
                }
            }
            PanelCard(title: copy.time) {
                ChoiceRow(labels: [copy.today, copy.thisMonth, copy.customRange], index: modeIndex) { index in
                    withAnimation(LedgerScreen.fold) {
                        mode = index == 0 ? .today : (index == 1 ? .month : .range)
                    }
                }
                if mode == .range {
                    HStack(spacing: 8) {
                        DateField(copy: copy, iso: $from, label: copy.rangeStart)
                        Text(copy.rangeTo)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                        DateField(copy: copy, iso: $to, label: copy.rangeEnd)
                    }
                    .padding(.top, 8)
                    .transition(.opacity)
                }
            }
            PillButton(title: copy.done) { pageBack() }
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
