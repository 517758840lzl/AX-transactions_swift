import Combine
import SwiftUI

struct RepeatPlanFormView: View {
    @ObservedObject var store: BookStore
    var planID: String?
    @Environment(\.pageBack) private var pageBack
    @State private var direction = Direction.out
    @State private var amount = ""
    @State private var title = ""
    @State private var category = ""
    @State private var accountID = ""
    @State private var shared = false
    @State private var countsInBudget = true
    @State private var day = "1"
    @State private var ready = false

    var body: some View {
        let copy = store.copy
        let existing = store.book.repeats.first { $0.id == planID }
        FormPage(title: copy.recurringTitle, back: copy.back) {
            ChoiceRow(labels: [copy.periodSpend, copy.monthIncome], index: direction == .out ? 0 : 1) { index in
                direction = index == 0 ? .out : .income
            }
            FieldLabel(text: copy.amount)
            LedgerField(text: $amount, placeholder: "0.00", decimal: true)
            FieldLabel(text: copy.name)
            LedgerField(text: $title, placeholder: copy.namePh)
            FieldLabel(text: copy.category)
            ChipWrap(names: store.book.categories, selected: category) { category = $0 }
            FieldLabel(text: copy.repeatDay)
            LedgerField(text: $day, placeholder: "1", decimal: true)
            FieldLabel(text: copy.account)
            accountField
            check(copy.shared, on: shared) { shared.toggle() }
            check(copy.countBudget, on: countsInBudget) { countsInBudget.toggle() }
            PillButton(title: copy.save, enabled: canSave) { save(existing: existing) }
            if existing != nil {
                Button(copy.deleteEntry) {
                    if let planID { store.deleteRepeat(planID) }
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

    private func check(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(on ? Palette.pink : Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(on ? Palette.pink : Palette.line, lineWidth: 1.5))
                    .overlay {
                        if on {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Palette.ink)
                        }
                    }
                    .frame(width: 22, height: 22)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.ink)
            }
        }
        .buttonStyle(.plain)
    }

    private var canSave: Bool {
        let value = Double(amount.trimmingCharacters(in: .whitespacesAndNewlines))
        let dayValue = Int(day.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (value ?? 0) > 0
            && !accountID.isEmpty
            && (1...28).contains(dayValue)
    }

    private func fill(_ existing: RepeatPlan?) {
        guard !ready else { return }
        ready = true
        if let existing {
            direction = existing.direction
            amount = LedgerMoney.fixed(existing.amount, fraction: 2)
            title = existing.title
            category = existing.category
            accountID = existing.accountId
            shared = existing.shared
            countsInBudget = existing.countsInBudget
            day = String(existing.day)
        } else {
            category = store.book.categories.first ?? store.copy.starterCategories[0]
            accountID = store.book.accounts.first?.id ?? ""
        }
    }

    private func save(existing: RepeatPlan?) {
        guard canSave, let value = Double(amount.trimmingCharacters(in: .whitespacesAndNewlines)), let dayValue = Int(day.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
        store.saveRepeat(RepeatPlan(
            id: existing?.id ?? LedgerID.make(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: value,
            direction: direction,
            category: category,
            accountId: accountID,
            shared: shared,
            countsInBudget: countsInBudget,
            day: dayValue,
            lastMonth: existing?.lastMonth ?? ""
        ))
        pageBack()
    }
}
