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
        let suggestions = BookMath.titleSuggestions(store.book.entries)
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(suggestions, id: \.self) { item in
                            Button(item) { title = item }
                                .font(.system(size: 13, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundStyle(title == item ? Color.white : Palette.ink)
                                .background(title == item ? Palette.ink : Color.white, in: Capsule())
                                .overlay(Capsule().stroke(Palette.line, lineWidth: 1))
                        }
                    }
                    .immediateScroll()
                }
            }
            FieldLabel(text: copy.category)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(store.book.categories, id: \.self) { name in
                        Button(name) { category = name }
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(category == name ? Color.white : Palette.ink)
                            .background(category == name ? Palette.ink : Color.white, in: Capsule())
                            .overlay(Capsule().stroke(Palette.line, lineWidth: 1))
                    }
                }
                .immediateScroll()
            }
            FieldLabel(text: copy.date)
            DatePicker(copy.date, selection: dateBinding, in: ...Date(), displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
            FieldLabel(text: copy.account)
            if store.book.accounts.isEmpty {
                LedgerField(text: $accountName, placeholder: copy.accountKindCash)
            } else {
                Picker(copy.account, selection: $accountID) {
                    ForEach(store.book.accounts) { account in
                        Text(account.name).tag(account.id)
                    }
                }
                .pickerStyle(.menu)
            }
            Toggle(copy.shared, isOn: $shared)
                .tint(Palette.pink)
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

    private var dateBinding: Binding<Date> {
        Binding(get: { LedgerDay.parse(date) }, set: { date = LedgerDay.iso($0) })
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
