//
//  TransferPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/21.
//

import Combine
import SwiftUI

struct TransferFormView: View {
    @ObservedObject var store: BookStore
    @Environment(\.pageBack) private var pageBack
    @State private var fromID = ""
    @State private var toID = ""
    @State private var amount = ""
    @State private var date = LedgerDay.today()
    @State private var ready = false

    var body: some View {
        let copy = store.copy
        FormPage(title: copy.transferTitle, back: copy.back) {
            FieldLabel(text: copy.transferFrom)
            accountChoice(copy.transferFrom, id: fromID) { fromID = $0 }
            FieldLabel(text: copy.transferTo)
            accountChoice(copy.transferTo, id: toID) { toID = $0 }
            FieldLabel(text: copy.amount)
            LedgerField(text: $amount, placeholder: "0.00", decimal: true)
            FieldLabel(text: copy.date)
            DateField(copy: copy, iso: $date, label: copy.date)
            PillButton(title: copy.save, enabled: canSave) { save() }
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
        let options = choices.map { ChoiceOption(id: $0.id, title: $0.name) }
        return ChoiceField(label: label, title: name, options: options, selectedID: id, onSelect: onSelect)
    }

    private var canSave: Bool {
        store.book.accounts.count >= 2 && fromID != toID && (Double(amount) ?? 0) > 0
    }

    private func save() {
        guard canSave, let value = Double(amount),
              let from = store.book.accounts.first(where: { $0.id == fromID }),
              let to = store.book.accounts.first(where: { $0.id == toID }) else { return }
        store.addTransfer(from: from, to: to, amount: value, date: date)
        pageBack()
    }
}
