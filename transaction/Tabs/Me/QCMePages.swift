//
//  QCMePages.swift
//  transaction
//
//  Created by Lzl on 2026/10/23.
//

import SwiftUI

struct QCCategoryManageView: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen
    @State private var editing = false

    var body: some View {
        let copy = store.copy
        QCFormPage(title: copy.categories, back: copy.back, place: "categories") {
            HStack {
                Spacer()
                Button(editing ? copy.done : copy.edit) { editing.toggle() }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(QCPalette.ink)
            }
            QCCategoryGrid(
                names: store.book.categories,
                marks: store.book.categoryMarks,
                editing: editing,
                canRemove: store.book.categories.count > 1,
                addTitle: copy.add,
                onRemove: { store.removeCategory($0) },
                onAdd: { screen.open(.categoryForm(slot: "manage")) }
            )
        }
    }
}

struct QCLanguagePickView: View {
    @ObservedObject var store: QCBookStore

    var body: some View {
        let copy = store.copy
        QCFormPage(title: copy.language, back: copy.back, place: "language") {
            let locales = [QCBookLocale.en] + QCBookLocale.allCases.filter { $0 != .en }
            pickCard(locales.map { locale in
                (locale.title, store.book.locale == locale, { store.setLocale(locale) })
            })
        }
    }
}

struct QCCurrencyPickView: View {
    @ObservedObject var store: QCBookStore

    var body: some View {
        let copy = store.copy
        QCFormPage(title: copy.currency, back: copy.back, place: "currency") {
            pickCard(QCCurrencyCode.allCases.map { code in
                ("\(code.rawValue)  \(code.mark)", store.book.currency == code, { store.setCurrency(code) })
            })
        }
    }
}

private func pickCard(_ rows: [(String, Bool, () -> Void)]) -> some View {
    VStack(spacing: 0) {
        ForEach(rows.indices, id: \.self) { index in
            Button(action: rows[index].2) {
                HStack(spacing: 12) {
                    Text(rows[index].0)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(QCPalette.ink)
                    Spacer(minLength: 8)
                    if rows[index].1 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(QCPalette.ink)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if index < rows.count - 1 {
                Rectangle().fill(QCPalette.line).frame(height: 1)
            }
        }
    }
    .padding(.horizontal, 16)
    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(QCPalette.line, lineWidth: 1))
}
