//
//  QCDashboardView.swift
//  transaction
//
//  Created by Lzl on 2026/10/15.
//

import SwiftUI

// A home foi partida em blocos porque o ficheiro chegou às duas mil linhas e o Xcode levava uma eternidade a compilar
// Cada bloco recebe store / screen / copy. Repete-se, mas embrulhar noutra camada só complicava, ficou assim
struct QCDashboardView: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen

    var body: some View {
        let copy = store.copy
        // Tirar os dados de exemplo antes de calcular, senão quem entra pela primeira vez vê números e pensa que são reais
        let inScope = QCBookMath.byScope(store.book.entries, screen.dashScope)
        let scoped = inScope.filter { !$0.id.hasPrefix("sample-") }
        let queue = QCBookMath.reviewQueue(scoped)

        VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: 8) {
            Text(copy.monthTitle())
                .font(.system(size: 26, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(QCPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Spacer(minLength: 8)
            Button {
                screen.open(.filter(which: "dashboard"))
            } label: {
                Text(screen.dashScope == .mine ? copy.scopeChipMine : copy.scopeChipFamily)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(QCPalette.ink)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white, in: Capsule())
                    .overlay(Capsule().stroke(QCPalette.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .fixedSize(horizontal: true, vertical: true)
        }
        .pageTitleBar()
        QCPageScroll(place: "dashboard", bottom: 128) {
            QCDashboardStatsPanel(store: store, screen: screen, copy: copy, entries: scoped)
            if scoped.isEmpty {
                QCDashboardEmptyBanners(store: store, screen: screen, copy: copy)
            }
            QCDashboardClaimPanel(store: store, screen: screen, copy: copy)
            QCDashboardReviewPanel(store: store, screen: screen, copy: copy, queue: queue)
            QCDashboardRecurringPanel(store: store, screen: screen, copy: copy)
        }
        }
    }
}
