import Combine
import SwiftUI

struct AccountFormView: View {
    @ObservedObject var store: BookStore
    var accountID: String?
    @Environment(\.pageBack) private var pageBack
    @State private var name = ""
    @State private var opening = ""
    @State private var kind = AccountKind.cash
    @State private var countsInWorth = true
    @State private var ready = false

    var body: some View {
        let copy = store.copy
        let editing = store.book.accounts.contains { $0.id == accountID }
        FormPage(title: editing ? copy.editAccount : copy.newAccount, back: copy.back) {
            FieldLabel(text: copy.accountName)
            LedgerField(text: $name, placeholder: copy.accountNamePh)
            FieldLabel(text: copy.accountKindLabel)
            ChoiceRow(labels: AccountKind.order.map { copy.accountKind($0) }, index: AccountKind.order.firstIndex(of: kind) ?? 0) { index in
                kind = AccountKind.order[index]
            }
            FieldLabel(text: copy.accountBalance)
            LedgerField(text: $opening, placeholder: "0.00", decimal: true)
            Button { countsInWorth.toggle() } label: {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(countsInWorth ? Palette.pink : Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(countsInWorth ? Palette.pink : Palette.line, lineWidth: 1.5))
                        .overlay {
                            if countsInWorth {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Palette.ink)
                            }
                        }
                        .frame(width: 22, height: 22)
                    Text(copy.countWorth)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                }
            }
            .buttonStyle(.plain)
            PillButton(title: copy.save, enabled: canSave) { save() }
            if editing {
                Button(copy.deleteAccount) {
                    if let accountID { store.removeAccount(accountID) }
                    pageBack()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.review)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            guard !ready, let account = store.book.accounts.first(where: { $0.id == accountID }) else {
                ready = true
                return
            }
            ready = true
            name = account.name
            opening = LedgerMoney.fixed(account.opening, fraction: 2)
            kind = account.kind
            countsInWorth = account.countsInWorth
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && Double(opening.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    private func save() {
        guard canSave, let value = Double(opening.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
        store.upsertAccount(Account(
            id: accountID ?? LedgerID.make(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            opening: LedgerMoney.cents(value),
            kind: kind,
            countsInWorth: countsInWorth
        ))
        pageBack()
    }
}
