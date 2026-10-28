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
            Picker(copy.transferFrom, selection: $fromID) {
                ForEach(store.book.accounts) { account in Text(account.name).tag(account.id) }
            }
            FieldLabel(text: copy.transferTo)
            Picker(copy.transferTo, selection: $toID) {
                ForEach(store.book.accounts) { account in Text(account.name).tag(account.id) }
            }
            FieldLabel(text: copy.amount)
            LedgerField(text: $amount, placeholder: "0.00", decimal: true)
            FieldLabel(text: copy.date)
            DatePicker(copy.date, selection: Binding(get: { LedgerDay.parse(date) }, set: { date = LedgerDay.iso($0) }), in: ...Date(), displayedComponents: .date)
                .labelsHidden()
            PillButton(title: copy.save, enabled: canSave) { save() }
        }
        .onAppear {
            guard !ready else { return }
            ready = true
            fromID = store.book.accounts.first?.id ?? ""
            toID = store.book.accounts.dropFirst().first?.id ?? fromID
        }
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
