//
//  QCTransferPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/21.
//

import SwiftUI

struct QCTransferFormView: View {
    @ObservedObject var store: QCBookStore
    @Environment(\.pageBack) private var pageBack
    @State private var fromID = ""
    @State private var toID = ""
    @State private var amount = ""
    @State private var date = QCLedgerDay.today()
    @State private var ready = false

    var body: some View {
        let copy = store.copy
        QCFormPage(title: copy.transferTitle, back: copy.back, place: "transfer") {
            QCFieldLabel(text: copy.transferFrom)
            accountChoice(copy.transferFrom, id: fromID) { fromID = $0 }
            QCFieldLabel(text: copy.transferTo)
            accountChoice(copy.transferTo, id: toID) { toID = $0 }
            QCFieldLabel(text: copy.amount)
            QCLedgerField(text: $amount, placeholder: "0.00", decimal: true)
            QCFieldLabel(text: copy.date)
            QCDateField(copy: copy, iso: $date, label: copy.date)
            QCPillButton(title: copy.save, enabled: canSave) { save() }
        }
        .onAppear {
            guard !ready else { return }
            ready = true
            fromID = store.openAccounts().first?.id ?? ""
            toID = store.openAccounts().dropFirst().first?.id ?? fromID
        }
    }

    private func accountChoice(_ label: String, id: String, onSelect: @escaping (String) -> Void) -> some View {
        let choices = store.openAccounts(keeping: id)
        let name = choices.first { $0.id == id }?.name ?? ""
        let options = choices.map { QCChoiceOption(id: $0.id, title: $0.name) }
        return QCChoiceField(label: label, title: name, options: options, selectedID: id, onSelect: onSelect)
    }

    private var canSave: Bool {
        let value = QCLedgerMoney.cents(Double(amount.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0)
        return store.book.accounts.count >= 2 && fromID != toID && value > 0
    }

    private func save() {
        guard canSave, let value = Double(amount),
              let from = store.book.accounts.first(where: { $0.id == fromID }),
              let to = store.book.accounts.first(where: { $0.id == toID }) else { return }
        store.addTransfer(from: from, to: to, amount: value, date: date)
        pageBack()
    }
}
