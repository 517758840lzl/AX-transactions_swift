//
//  QCBudgetPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/16.
//

import SwiftUI

struct QCBudgetFormView: View {
    @ObservedObject var store: QCBookStore
    @Environment(\.pageBack) private var pageBack
    @State private var monthly = ""
    @State private var caps: [String: String] = [:]
    @State private var ready = false

    var body: some View {
        let copy = store.copy
        QCFormPage(title: copy.monthlyBudget, back: copy.back, place: "budget") {
            Text(copy.budgetHint).font(.system(size: 13)).foregroundStyle(QCPalette.muted)
            QCLedgerField(text: $monthly, placeholder: "5000.00", decimal: true)
            Text(copy.categoryBudget).font(.system(size: 16, weight: .bold))
            Text(copy.categoryBudgetHint).font(.system(size: 13)).foregroundStyle(QCPalette.muted)
            ForEach(store.book.categories, id: \.self) { name in
                QCFieldLabel(text: name)
                QCLedgerField(text: capBinding(name), placeholder: categoryHint(name), decimal: true)
            }
            QCPillButton(title: copy.save) { save() }
            if store.book.monthlyBudget != nil || !store.book.categoryCaps.isEmpty {
                Button(copy.budgetClear) {
                    store.saveBudget(monthly: nil, caps: [:], clear: true)
                    pageBack()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(QCPalette.review)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            guard !ready else { return }
            ready = true
            if let value = store.book.monthlyBudget { monthly = QCLedgerMoney.fixed(value, fraction: 2) }
            caps = store.book.categoryCaps.mapValues { QCLedgerMoney.fixed($0, fraction: 2) }
        }
    }

    private func capBinding(_ name: String) -> Binding<String> {
        Binding(get: { caps[name] ?? "" }, set: { caps[name] = $0 })
    }

    private func categoryHint(_ name: String) -> String {
        QCLedgerMoney.fixed(store.copy.categoryHint(name), fraction: 2)
    }

    private func save() {
        let trimmed = monthly.trimmingCharacters(in: .whitespacesAndNewlines)
        let monthlyValue = trimmed.isEmpty ? nil : Double(trimmed)
        var next: [String: Double] = [:]
        for (name, text) in caps {
            let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if let value = Double(clean), value > 0 { next[name] = QCLedgerMoney.cents(value) }
        }
        let clear = monthlyValue == nil && next.isEmpty
        let rounded: Double?
        if let monthlyValue {
            rounded = QCLedgerMoney.cents(monthlyValue)
        } else {
            rounded = nil
        }
        store.saveBudget(monthly: rounded, caps: next, clear: clear)
        pageBack()
    }
}
