//
//  BookExportPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/28.
//

import Combine
import SwiftUI

struct BookExportPage: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen

    var body: some View {
        let copy = store.copy
        let book = store.book
        FormPage(title: copy.dataManage, back: copy.back) {
            PanelCard {
                HStack(spacing: 0) {
                    stat(book.entries.count, copy.transactions) { showTab(1) }
                    Rectangle().fill(Palette.line).frame(width: 1, height: 36)
                    stat(book.accounts.count, copy.accounts) { showTab(2) }
                    Rectangle().fill(Palette.line).frame(width: 1, height: 36)
                    stat(book.holdings.count, copy.holdingsLabel) { showTab(2) }
                }
            }
            Button {
                ShareSheet.present(store.exportText())
            } label: {
                PanelCard {
                    HStack(spacing: 14) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                            .frame(width: 44, height: 44)
                            .background(Palette.pink, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(copy.exportBackup)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Palette.ink)
                            Text(copy.dataExportNote)
                                .font(.system(size: 13))
                                .foregroundStyle(Palette.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Palette.faint)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func stat(_ count: Int, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func showTab(_ index: Int) {
        screen.tab = index
        screen.path = []
    }
}
