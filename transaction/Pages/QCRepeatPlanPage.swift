//
//  QCRepeatPlanPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/27.
//

import SwiftUI

struct QCRepeatPlanFormView: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen
    var planID: String?
    @Environment(\.pageBack) private var pageBack
    @State private var direction = QCDirection.out
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
        QCFormPage(title: copy.recurringTitle, back: copy.back, place: "repeat-\(planID ?? "new")") {
            QCChoiceRow(labels: [copy.periodSpend, copy.monthIncome], index: direction == .out ? 0 : 1) { index in
                direction = index == 0 ? .out : .income
            }
            QCFieldLabel(text: copy.amount)
            QCLedgerField(text: $amount, placeholder: "0.00", decimal: true)
            QCFieldLabel(text: copy.name)
            QCLedgerField(text: $title, placeholder: copy.namePh)
            QCFieldLabel(text: copy.category)
            QCCategoryGrid(names: store.book.categories, marks: store.book.categoryMarks, selected: category, rows: 4, addTitle: copy.add, onSelect: { category = $0 }, onAdd: { screen.open(.categoryForm(slot: "plan")) })
            QCFieldLabel(text: copy.repeatDay)
            QCLedgerField(text: $day, placeholder: "1", decimal: true)
            QCFieldLabel(text: copy.account)
            accountField
            check(copy.shared, on: shared) { shared.toggle() }
            check(copy.countBudget, on: countsInBudget) { countsInBudget.toggle() }
            QCPillButton(title: copy.save, enabled: canSave) { save(existing: existing) }
            if existing != nil {
                Button(copy.deleteEntry) {
                    if let planID { store.deleteRepeat(planID) }
                    pageBack()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(QCPalette.down)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { fill(existing) }
        .onChange(of: screen.categoryPickName) { picked in
            guard !picked.isEmpty, screen.categoryPickSlot == "plan" else { return }
            category = picked
            screen.categoryPickName = ""
        }
    }

    private var accountField: some View {
        let name = store.book.accounts.first { $0.id == accountID }?.name ?? ""
        let options = store.book.accounts.map { QCChoiceOption(id: $0.id, title: $0.name) }
        return QCChoiceField(label: store.copy.account, title: name, options: options, selectedID: accountID) {
            accountID = $0
        }
    }

    private func check(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(on ? QCPalette.pink : Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(on ? QCPalette.pink : QCPalette.line, lineWidth: 1.5))
                    .overlay {
                        if on {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(QCPalette.ink)
                        }
                    }
                    .frame(width: 22, height: 22)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(QCPalette.ink)
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

    private func fill(_ existing: QCRepeatPlan?) {
        guard !ready else { return }
        ready = true
        if let existing {
            direction = existing.direction
            amount = QCLedgerMoney.fixed(existing.amount, fraction: 2)
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

    private func save(existing: QCRepeatPlan?) {
        guard canSave, let value = Double(amount.trimmingCharacters(in: .whitespacesAndNewlines)), let dayValue = Int(day.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
        store.saveRepeat(QCRepeatPlan(
            id: existing?.id ?? QCLedgerID.make(),
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
