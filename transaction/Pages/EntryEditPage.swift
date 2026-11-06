//
//  EntryEditPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/9.
//

import Combine
import SwiftUI
import UIKit

struct EntryFormView: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
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
    @State private var tried = false

    var body: some View {
        let copy = store.copy
        let existing = store.book.entries.first { $0.id == entryID }
        let suggestions = BookMath.titleSuggestions(store.book.entries, locale: store.book.locale, transferCategory: copy.transferCategory)
        FormPage(title: existing == nil ? copy.entryNew : copy.entryEdit, back: copy.back, place: "entry-\(entryID ?? "new")", side: 8) {
            ChoiceRow(labels: [copy.periodSpend, copy.monthIncome, copy.transfer], index: direction == .out ? 0 : 1) { index in
                if index == 2 {
                    let own = store.book.accounts.filter { !$0.id.hasPrefix("sample-") }
                    if own.count < 2 {
                        store.flash(copy.transferNeedTwo)
                    } else {
                        screen.open(.transfer)
                    }
                    return
                }
                withAnimation(LedgerScreen.fold) {
                    direction = index == 0 ? .out : .income
                }
            }
            FieldLabel(text: copy.amount)
            LedgerField(text: $amount, placeholder: "0.00", decimal: true, marked: tried && !amountReady)
                .background(EntryMark(id: "entry-amount"))
            FieldLabel(text: copy.name)
            LedgerField(text: $title, placeholder: copy.namePh, marked: tried && !titleReady)
                .background(EntryMark(id: "entry-title"))
            if !suggestions.isEmpty {
                FieldLabel(text: copy.titleSuggestions)
                ChipWrap(names: suggestions, selected: title) { title = $0 }
            }
            FieldLabel(text: copy.category)
            CategoryGrid(names: store.book.categories, marks: store.book.categoryMarks, selected: category, rows: 4, addTitle: copy.add, onSelect: { category = $0 }, onAdd: { screen.open(.categoryForm(slot: "entry")) })
            if existing == nil {
                checkRow(copy.splitMark, on: splitOn) {
                    withAnimation(LedgerScreen.fold) { splitOn.toggle() }
                }
            }
            if splitOn && existing == nil {
                VStack(alignment: .leading, spacing: 14) {
                    FieldLabel(text: copy.splitAmount)
                    LedgerField(text: $otherAmount, placeholder: "0.00", decimal: true, marked: tried && splitOn && existing == nil && !otherReady)
                        .background(EntryMark(id: "entry-other"))
                    FieldLabel(text: copy.category)
                    CategoryGrid(names: store.book.categories, marks: store.book.categoryMarks, selected: otherCategory, rows: 4, addTitle: copy.add, onSelect: { otherCategory = $0 }, onAdd: { screen.open(.categoryForm(slot: "other")) })
                    checkRow(copy.shared, on: otherShared) { otherShared.toggle() }
                }
                .transition(.opacity)
            }
            FieldLabel(text: copy.date)
            DateField(copy: copy, iso: $date, label: copy.date, marked: tried && !dateReady)
                .background(EntryMark(id: "entry-date"))
            FieldLabel(text: copy.account)
            if store.openAccounts(keeping: accountID).isEmpty {
                Text(copy.accountNone)
                    .font(.system(size: 16))
                    .foregroundStyle(Palette.muted)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(tried && !accountReady ? Palette.down : Palette.line, lineWidth: 1))
                    .allowsHitTesting(false)
                    .background(EntryMark(id: "entry-account"))
            } else {
                accountField
            }
            if needsAccountGuide {
                Button {
                    screen.open(.accountForm(id: nil, chooseKind: true))
                } label: {
                    HStack(spacing: 8) {
                        Text(copy.accountGuide)
                            .font(.system(size: 14, weight: .semibold))
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        Text("›")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(Palette.ink)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Palette.wash, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            if direction == .out, !splitOn, !store.book.goals.isEmpty {
                goalField
                    .transition(.opacity)
            }
            sharedBox(copy)
            checkRow(copy.countBudget, on: countsInBudget) { countsInBudget.toggle() }
            if direction == .out {
                checkRow(claim == .done ? copy.claimDone : copy.claimMark, on: claim != .none) {
                    claim = claim == .none ? .waiting : .none
                }
                .transition(.opacity)
            }
            PillButton(title: copy.save, faded: !canSave) {
                guard canSave else {
                    tried = true
                    if let id = firstGap { revealEntry(id) }
                    return
                }
                save(existing: existing)
            }
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
        .onChange(of: screen.categoryPickName) { picked in
            guard !picked.isEmpty else { return }
            if screen.categoryPickSlot == "entry" { category = picked }
            if screen.categoryPickSlot == "other" { otherCategory = picked }
            if screen.categoryPickSlot == "entry" || screen.categoryPickSlot == "other" {
                screen.categoryPickName = ""
            }
        }
        .onChange(of: store.book.accounts.map(\.id).joined(separator: ",")) { _ in
            guard entryID == nil || accountID.isEmpty else { return }
            let own = store.openAccounts().filter { !$0.id.hasPrefix("sample-") }
            guard let latest = own.last, !own.contains(where: { $0.id == accountID }) else { return }
            accountID = latest.id
        }
    }

    private var needsAccountGuide: Bool {
        store.openAccounts(keeping: accountID).allSatisfy { $0.id.hasPrefix("sample-") }
    }

    private var accountField: some View {
        let choices = store.openAccounts(keeping: accountID)
        let name = choices.first { $0.id == accountID }?.name ?? ""
        let options = choices.map { ChoiceOption(id: $0.id, title: $0.name) }
        return ChoiceField(label: store.copy.account, title: name, options: options, selectedID: accountID, marked: tried && !accountReady) {
            accountID = $0
        }
        .background(EntryMark(id: "entry-account"))
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

    private var amountReady: Bool {
        LedgerMoney.cents(LedgerMoney.solve(amount.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0) > 0
    }

    private var titleReady: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var dateReady: Bool {
        !date.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var accountReady: Bool {
        entryID != nil || store.openAccounts(keeping: accountID).contains { $0.id == accountID && !$0.id.hasPrefix("sample-") }
    }

    private var otherReady: Bool {
        let other = LedgerMoney.cents(LedgerMoney.solve(otherAmount.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0)
        return other > 0 && !otherCategory.isEmpty
    }

    private var canSave: Bool {
        guard titleReady, amountReady, dateReady, accountReady else { return false }
        if splitOn, entryID == nil { return otherReady }
        return true
    }

    private struct EntryMark: UIViewRepresentable {
        var id: String

        func makeUIView(context: Context) -> UIView {
            let view = UIView()
            view.isUserInteractionEnabled = false
            view.backgroundColor = .clear
            view.accessibilityIdentifier = id
            return view
        }

        func updateUIView(_ view: UIView, context: Context) {
            view.accessibilityIdentifier = id
        }
    }

    private func revealEntry(_ id: String) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        scrollEntry(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { scrollEntry(id) }
    }

    private func scrollEntry(_ id: String) {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        for window in windows {
            guard let target = markedView(id, in: window), let scroll = scrollOwner(of: target) else { continue }
            let rect = target.convert(target.bounds, to: scroll).insetBy(dx: 0, dy: -36)
            scroll.scrollRectToVisible(rect, animated: true)
            return
        }
    }

    private func markedView(_ id: String, in view: UIView) -> UIView? {
        if view.accessibilityIdentifier == id { return view }
        for child in view.subviews {
            if let found = markedView(id, in: child) { return found }
        }
        return nil
    }

    private func scrollOwner(of view: UIView) -> UIScrollView? {
        var current = view.superview
        while let next = current {
            if let scroll = next as? UIScrollView { return scroll }
            current = next.superview
        }
        return nil
    }

    private var firstGap: String? {
        if !amountReady { return "entry-amount" }
        if !titleReady { return "entry-title" }
        if splitOn, entryID == nil, !otherReady { return "entry-other" }
        if !dateReady { return "entry-date" }
        if !accountReady { return "entry-account" }
        return nil
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
            direction = screen.entryDirection
            category = store.book.categories.first ?? store.copy.starterCategories[0]
            otherCategory = category
            accountID = store.openAccounts().first?.id ?? ""
            accountName = store.openAccounts().first?.name ?? ""
        }
    }

    private func save(existing: Entry?) {
        guard canSave, let value = LedgerMoney.solve(amount.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
        let named = title.trimmingCharacters(in: .whitespacesAndNewlines)
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
        let stored = store.saveEntry(entry)
        if splitting, let other = LedgerMoney.solve(otherAmount.trimmingCharacters(in: .whitespacesAndNewlines)) {
            var second = stored
            second.id = LedgerID.make()
            second.amount = other
            second.category = otherCategory
            second.shared = otherShared
            second.goalId = ""
            second.refundOf = ""
            second.claim = direction == .out ? claim : .none
            store.saveEntry(second)
        }
        pageBack()
    }
}
