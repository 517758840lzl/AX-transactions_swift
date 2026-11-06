//
//  QCBookExportPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/28.
//

import SwiftUI

struct QCBookExportPage: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen

    var body: some View {
        let copy = store.copy
        let book = store.book
        QCFormPage(title: copy.dataManage, back: copy.back, place: "export") {
            QCPanelCard {
                HStack(spacing: 0) {
                    stat(book.entries.count, copy.transactions) { showTab(1) }
                    Rectangle().fill(QCPalette.line).frame(width: 1, height: 36)
                    stat(book.accounts.count, copy.accounts) { screen.open(.accountsHome) }
                }
            }
            Button {
                QCShareSheet.present(store.exportText())
            } label: {
                QCPanelCard {
                    HStack(spacing: 14) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(QCPalette.ink)
                            .frame(width: 44, height: 44)
                            .background(QCPalette.pink, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(copy.exportBackup)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(QCPalette.ink)
                            Text(copy.dataExportNote)
                                .font(.system(size: 13))
                                .foregroundStyle(QCPalette.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(QCPalette.faint)
                    }
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            Button {
                let payload = QCExcelBook.data(book: book, copy: copy)
                let filename = "\(QCBundleTitle.current).xlsx"
                QCShareSheet.present(data: payload, filename: filename)
            } label: {
                QCPanelCard {
                    HStack(spacing: 14) {
                        Image(systemName: "tablecells")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(QCPalette.ink)
                            .frame(width: 44, height: 44)
                            .background(QCPalette.pink, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(copy.exportExcel)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(QCPalette.ink)
                            Text(copy.dataExcelNote)
                                .font(.system(size: 13))
                                .foregroundStyle(QCPalette.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(QCPalette.faint)
                    }
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityLabel(copy.exportExcel)
        }
    }

    private func stat(_ count: Int, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(QCPalette.ink)
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(QCPalette.muted)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func showTab(_ index: Int) {
        screen.reveal(tab: index)
    }
}
