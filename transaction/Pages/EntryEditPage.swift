//
//  EntryEditPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/9.
//

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
    @State private var countsInBudget = true
    @State private var claim = ClaimMark.none
    @State private var goalId = ""
    @State private var splitOn = false
    @State private var otherAmount = ""
    @State private var otherCategory = ""
    @State private var otherShared = false
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
            HStack(spacing: 8) {
                mathButton("+", enabled: canAppendMark) { amount += "+" }
                mathButton("−", enabled: canAppendMark) { amount += "-" }
                Button(copy.amountSolve) { applySolve() }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(showsSolve ? Palette.ink : Palette.faint)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 40)
                    .background(showsSolve ? Palette.pink : Palette.neutral, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .disabled(!showsSolve)
            }
            FieldLabel(text: copy.name)
            LedgerField(text: $title, placeholder: copy.namePh)
            if !suggestions.isEmpty {
                FieldLabel(text: copy.titleSuggestions)
                ChipWrap(names: suggestions, selected: title) { title = $0 }
            }
            FieldLabel(text: copy.category)
            ChipWrap(names: store.book.categories, selected: category) { category = $0 }
            if existing == nil {
                checkRow(copy.splitMark, on: splitOn) { splitOn.toggle() }
            }
            if splitOn && existing == nil {
                FieldLabel(text: copy.splitAmount)
                LedgerField(text: $otherAmount, placeholder: "0.00", decimal: true)
                FieldLabel(text: copy.category)
                ChipWrap(names: store.book.categories, selected: otherCategory) { otherCategory = $0 }
                checkRow(copy.shared, on: otherShared) { otherShared.toggle() }
            }
            FieldLabel(text: copy.date)
            DateField(copy: copy, iso: $date, label: copy.date)
            FieldLabel(text: copy.account)
            if store.openAccounts(keeping: accountID).isEmpty {
                LedgerField(text: $accountName, placeholder: copy.accountKindCash)
            } else {
                accountField
            }
            if direction == .out, !splitOn, !store.book.goals.isEmpty {
                goalField
            }
            sharedBox(copy)
            checkRow(copy.countBudget, on: countsInBudget) { countsInBudget.toggle() }
            if direction == .out {
                checkRow(claim == .done ? copy.claimDone : copy.claimMark, on: claim != .none) {
                    claim = claim == .none ? .waiting : .none
                }
            }
            PillButton(title: copy.save, enabled: canSave) { save(existing: existing) }
            if let existing, existing.isOut, existing.refundOf.isEmpty {
                let refunded = store.book.entries.contains { $0.refundOf == existing.id }
                if refunded {
                    Text(copy.refundDone)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Palette.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Palette.wash, in: Capsule())
                } else {
                    PillButton(title: copy.refundMark, filled: false) {
                        store.refund(existing)
                        pageBack()
                    }
                }
            }
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
        let choices = store.openAccounts(keeping: accountID)
        let name = choices.first { $0.id == accountID }?.name ?? ""
        let options = choices.map { ChoiceOption(id: $0.id, title: $0.name) }
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

    private func checkRow(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(on ? Palette.pink : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(on ? Palette.pink : Palette.line, lineWidth: 1.5)
                    )
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
        .padding(.top, 6)
    }

    private var goalField: some View {
        let copy = store.copy
        let name = store.book.goals.first { $0.id == goalId }?.title ?? copy.goalNone
        var options = [ChoiceOption(id: "", title: copy.goalNone)]
        options += store.book.goals.map { ChoiceOption(id: $0.id, title: $0.title) }
        return VStack(alignment: .leading, spacing: 8) {
            FieldLabel(text: copy.goalAttach)
            ChoiceField(label: copy.goalAttach, title: name, options: options, selectedID: goalId) {
                goalId = $0
            }
        }
    }

    private var canAppendMark: Bool {
        guard let value = LedgerMoney.solve(amount) else { return false }
        return value > 0
    }

    private var showsSolve: Bool {
        let marks: Set<Character> = ["+", "-", "－", "−"]
        return amount.contains(where: { marks.contains($0) }) && canAppendMark
    }

    private func mathButton(_ title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(enabled ? Palette.ink : Palette.faint)
                .frame(minWidth: 52, minHeight: 40)
                .background(enabled ? Color.white : Palette.neutral, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func applySolve() {
        guard let value = LedgerMoney.solve(amount), value > 0 else { return }
        amount = LedgerMoney.fixed(value, fraction: 2)
    }

    private var canSave: Bool {
        let value = LedgerMoney.solve(amount.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let titled = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard titled, value > 0 else { return false }
        if splitOn, entryID == nil {
            let other = LedgerMoney.solve(otherAmount.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            return other > 0 && !otherCategory.isEmpty
        }
        return true
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
            countsInBudget = existing.countsInBudget
            claim = existing.claim
            goalId = existing.goalId
        } else {
            category = store.book.categories.first ?? store.copy.starterCategories[0]
            otherCategory = category
            accountID = store.openAccounts().first?.id ?? ""
            if accountName.isEmpty { accountName = store.copy.accountKindCash }
        }
    }

    private func save(existing: Entry?) {
        guard canSave, let value = LedgerMoney.solve(amount.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
        let named = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let fresh = store.openAccounts(keeping: accountID).isEmpty ? accountName : nil
        let firstID = existing?.id ?? LedgerID.make()
        let splitting = splitOn && existing == nil
        let entry = Entry(
            id: firstID,
            title: named,
            amount: value,
            direction: direction,
            category: category,
            date: date,
            accountName: accountName,
            accountId: accountID,
            checked: existing?.checked ?? false,
            shared: shared,
            countsInBudget: countsInBudget,
            claim: direction == .out ? claim : .none,
            refundOf: existing?.refundOf ?? "",
            goalId: direction == .out && !splitting ? goalId : "",
            splitGroup: splitting ? firstID : (existing?.splitGroup ?? "")
        )
        let stored = store.saveEntry(entry, creatingCashNamed: fresh)
        if splitting, let other = LedgerMoney.solve(otherAmount.trimmingCharacters(in: .whitespacesAndNewlines)) {
            var second = stored
            second.id = LedgerID.make()
            second.amount = other
            second.category = otherCategory
            second.shared = otherShared
            second.goalId = ""
            second.refundOf = ""
            second.claim = direction == .out ? claim : .none
            store.saveEntry(second, creatingCashNamed: nil)
        }
        pageBack()
    }
}
