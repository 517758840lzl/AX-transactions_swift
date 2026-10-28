import Combine
import SwiftUI

struct EntryFormView: View {
    @ObservedObject var store: BookStore
    var entryID: String?
    @Environment(\.pageBack) private var pageBack
    @State private var direction = Direction.out
    @State private var amount = ""
    @State private var title = ""
    @State private var category = ""
    @State private var date = LedgerDay.today()
    @State private var accountID = ""
    @State private var accountName = ""
    @State private var shared = false
    @State private var ready = false

    var body: some View {
        let copy = store.copy
        let existing = store.book.entries.first { $0.id == entryID }
        let suggestions = BookMath.titleSuggestions(store.book.entries, localeID: copy.localeID, transferCategory: copy.transferCategory)
        FormPage(title: existing == nil ? copy.entryNew : copy.entryEdit, back: copy.back) {
            ChoiceRow(labels: [copy.periodSpend, copy.monthIncome], index: direction == .out ? 0 : 1) { index in
                direction = index == 0 ? .out : .income
            }
            FieldLabel(text: copy.amount)
            LedgerField(text: $amount, placeholder: "0.00", decimal: true)
            FieldLabel(text: copy.name)
            LedgerField(text: $title, placeholder: copy.namePh)
            if !suggestions.isEmpty {
                FieldLabel(text: copy.titleSuggestions)
                ChipWrap(names: suggestions, selected: title) { title = $0 }
            }
            FieldLabel(text: copy.category)
            ChipWrap(names: store.book.categories, selected: category) { category = $0 }
            FieldLabel(text: copy.date)
            DateField(copy: copy, iso: $date, label: copy.date)
            FieldLabel(text: copy.account)
            if store.book.accounts.isEmpty {
                LedgerField(text: $accountName, placeholder: copy.accountKindCash)
            } else {
                accountField
            }
            sharedBox(copy)
            PillButton(title: copy.save, enabled: canSave) { save(existing: existing) }
            if existing != nil {
                Button(copy.deleteEntry) {
                    if let id = entryID { store.deleteEntry(id) }
                    pageBack()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.down)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { fill(existing) }
    }

    private var accountField: some View {
        let name = store.book.accounts.first { $0.id == accountID }?.name ?? ""
        let options = store.book.accounts.map { ChoiceOption(id: $0.id, title: $0.name) }
        return ChoiceField(label: store.copy.account, title: name, options: options, selectedID: accountID) {
            accountID = $0
        }
    }

    private func sharedBox(_ copy: LedgerCopy) -> some View {
        Button { shared.toggle() } label: {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(shared ? Palette.pink : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(shared ? Palette.pink : Palette.line, lineWidth: 1.5)
                    )
                    .overlay {
                        if shared {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Palette.ink)
                        }
                    }
                    .frame(width: 22, height: 22)
                Text(copy.shared)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.ink)
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }

    private var canSave: Bool {
        let value = Double(amount.trimmingCharacters(in: .whitespacesAndNewlines))
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (value ?? 0) > 0
    }

    private func fill(_ existing: Entry?) {
        guard !ready else { return }
        ready = true
        if let existing {
            direction = existing.direction
            amount = LedgerMoney.fixed(existing.amount, fraction: 2)
            title = existing.title
            category = existing.category
            date = existing.date
            accountID = existing.accountId
            accountName = existing.accountName
            shared = existing.shared
        } else {
            category = store.book.categories.first ?? store.copy.starterCategories[0]
            accountID = store.book.accounts.first?.id ?? ""
            if accountName.isEmpty { accountName = store.copy.accountKindCash }
        }
    }

    private func save(existing: Entry?) {
        guard canSave, let value = Double(amount.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
        let entry = Entry(
            id: existing?.id ?? LedgerID.make(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: value,
            direction: direction,
            category: category,
            date: date,
            accountName: accountName,
            accountId: accountID,
            checked: existing?.checked ?? false,
            shared: shared
        )
        store.saveEntry(entry, creatingCashNamed: store.book.accounts.isEmpty ? accountName : nil)
        pageBack()
    }
}
