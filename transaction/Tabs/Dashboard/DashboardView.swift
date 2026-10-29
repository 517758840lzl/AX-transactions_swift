//
//  DashboardView.swift
//  transaction
//
//  Created by Lzl on 2026/10/15.
//

import Combine
import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen

    var body: some View {
        let copy = store.copy
        let scoped = BookMath.byScope(store.book.entries, screen.dashScope)
        let queue = BookMath.reviewQueue(scoped)
        let showSample = !store.book.sampleCleared && store.book.entries.contains { $0.id.hasPrefix("sample-") }

        PageScroll(bottom: 88) {
            HStack {
                Text(copy.monthTitle()).font(.system(size: 26, weight: .bold)).tracking(-0.4).foregroundStyle(Palette.ink)
                Spacer()
                Button(screen.dashScope == .mine ? copy.scopeChipMine : copy.scopeChipFamily) {
                    screen.open(.filter(which: "dashboard"))
                }
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white, in: Capsule())
                .overlay(Capsule().stroke(Palette.line, lineWidth: 1))
            }
            DashboardStatsPanel(store: store, screen: screen, copy: copy, entries: scoped)
            DashboardClaimPanel(store: store, screen: screen, copy: copy)
            DashboardReviewPanel(store: store, screen: screen, copy: copy, queue: queue)
            DashboardRecurringPanel(store: store, screen: screen, copy: copy)
            if showSample {
                SampleBanner(title: copy.sampleBanner, actionTitle: copy.sampleClear) {
                    store.clearSample()
                }
            }
        }
    }
}
