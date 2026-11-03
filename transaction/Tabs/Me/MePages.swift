//
//  MePages.swift
//  transaction
//
//  Created by Lzl on 2026/10/23.
//

import Combine
import SwiftUI

struct CategoryManageView: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
    @State private var editing = false

    var body: some View {
        let copy = store.copy
        FormPage(title: copy.categories, back: copy.back) {
            HStack {
                Spacer()
                Button(editing ? copy.done : copy.edit) { editing.toggle() }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Palette.ink)
            }
            CategoryGrid(
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

struct LanguagePickView: View {
    @ObservedObject var store: BookStore

    var body: some View {
        let copy = store.copy
        FormPage(title: copy.language, back: copy.back) {
            pickCard(BookLocale.allCases.map { locale in
                (locale.title, store.book.locale == locale, { store.setLocale(locale) })
            })
        }
    }
}

struct CurrencyPickView: View {
    @ObservedObject var store: BookStore

    var body: some View {
        let copy = store.copy
        FormPage(title: copy.currency, back: copy.back) {
            pickCard(CurrencyCode.allCases.map { code in
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
                        .foregroundStyle(Palette.ink)
                    Spacer(minLength: 8)
                    if rows[index].1 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Palette.ink)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if index < rows.count - 1 {
                Rectangle().fill(Palette.line).frame(height: 1)
            }
        }
    }
    .padding(.horizontal, 16)
    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Palette.line, lineWidth: 1))
}
