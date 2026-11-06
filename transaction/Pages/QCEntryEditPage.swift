//
//  QCEntryEditPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/9.
//

import SwiftUI
import UIKit

struct QCEntryFormView: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen
    var entryID: String?
    @Environment(\.pageBack) private var pageBack
    @State private var direction = QCDirection.out
    @State private var amount = ""
    @State private var title = ""
    @State private var category = ""
    @State private var date = QCLedgerDay.today()
    @State private var accountID = ""
    @State private var accountName = ""
    @State private var shared = false
    @State private var countsInBudget = true
    @State private var claim = QCClaimMark.none
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
        let suggestions = QCBookMath.titleSuggestions(store.book.entries, locale: store.book.locale, transferCategory: copy.transferCategory)
        QCFormPage(title: existing == nil ? copy.entryNew : copy.entryEdit, back: copy.back, place: "entry-\(entryID ?? "new")", side: 8) {
            QCChoiceRow(labels: [copy.periodSpend, copy.monthIncome, copy.transfer], index: direction == .out ? 0 : 1) { index in
                if index == 2 {
                    let own = store.book.accounts.filter { !$0.id.hasPrefix("sample-") }
                    if own.count < 2 {
                        screen.open(.accountForm(id: nil, chooseKind: true))
                    } else {
                        screen.open(.transfer)
                    }
                    return
                }
                withAnimation(QCLedgerScreen.fold) {
                    direction = index == 0 ? .out : .income
                }
            }
            QCFieldLabel(text: copy.amount)
            QCLedgerField(text: $amount, placeholder: "0.00", decimal: true, marked: tried && !amountReady)
                .background(QCEntryMark(id: "entry-amount"))
            QCFieldLabel(text: copy.name)
            QCLedgerField(text: $title, placeholder: copy.namePh, marked: tried && !titleReady)
                .background(QCEntryMark(id: "entry-title"))
            if !suggestions.isEmpty {
                QCFieldLabel(text: copy.titleSuggestions)
                QCChipWrap(names: suggestions, selected: title) { title = $0 }
            }
            QCFieldLabel(text: copy.category)
            QCCategoryGrid(names: store.book.categories, marks: store.book.categoryMarks, selected: category, rows: 4, addTitle: copy.add, onSelect: { category = $0 }, onAdd: { screen.open(.categoryForm(slot: "entry")) })
            if existing == nil {
                checkRow(copy.splitMark, on: splitOn) {
                    withAnimation(QCLedgerScreen.fold) { splitOn.toggle() }
                }
            }
            if splitOn && existing == nil {
                VStack(alignment: .leading, spacing: 14) {
                    QCFieldLabel(text: copy.splitAmount)
                    QCLedgerField(text: $otherAmount, placeholder: "0.00", decimal: true, marked: tried && splitOn && existing == nil && !otherReady)
                        .background(QCEntryMark(id: "entry-other"))
                    QCFieldLabel(text: copy.category)
                    QCCategoryGrid(names: store.book.categories, marks: store.book.categoryMarks, selected: otherCategory, rows: 4, addTitle: copy.add, onSelect: { otherCategory = $0 }, onAdd: { screen.open(.categoryForm(slot: "other")) })
                    checkRow(copy.shared, on: otherShared) { otherShared.toggle() }
                }
                .transition(.opacity)
            }
            QCFieldLabel(text: copy.date)
            QCDateField(copy: copy, iso: $date, label: copy.date, marked: tried && !dateReady)
                .background(QCEntryMark(id: "entry-date"))
            QCFieldLabel(text: copy.account)
            if store.openAccounts(keeping: accountID).isEmpty {
                Text(copy.accountNone)
                    .font(.system(size: 16))
                    .foregroundStyle(QCPalette.muted)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(tried && !accountReady ? QCPalette.down : QCPalette.line, lineWidth: 1))
                    .allowsHitTesting(false)
                    .background(QCEntryMark(id: "entry-account"))
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
                    .foregroundColor(QCPalette.ink)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(QCPalette.wash, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
            QCPillButton(title: copy.save, faded: !canSave) {
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
                        .foregroundStyle(QCPalette.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(QCPalette.wash, in: Capsule())
                } else {
                    QCPillButton(title: copy.refundMark, filled: false) {
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
                .foregroundStyle(QCPalette.down)
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
        let options = choices.map { QCChoiceOption(id: $0.id, title: $0.name) }
        return QCChoiceField(label: store.copy.account, title: name, options: options, selectedID: accountID, marked: tried && !accountReady) {
            accountID = $0
        }
        .background(QCEntryMark(id: "entry-account"))
    }

    private func sharedBox(_ copy: QCLedgerCopy) -> some View {
        Button { shared.toggle() } label: {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(shared ? QCPalette.pink : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(shared ? QCPalette.pink : QCPalette.line, lineWidth: 1.5)
                    )
                    .overlay {
                        if shared {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(QCPalette.ink)
                        }
                    }
                    .frame(width: 22, height: 22)
                Text(copy.shared)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(QCPalette.ink)
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }

    private func checkRow(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(on ? QCPalette.pink : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(on ? QCPalette.pink : QCPalette.line, lineWidth: 1.5)
                    )
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
        .padding(.top, 6)
    }

    private var goalField: some View {
        let copy = store.copy
        let name = store.book.goals.first { $0.id == goalId }?.title ?? copy.goalNone
        var options = [QCChoiceOption(id: "", title: copy.goalNone)]
        options += store.book.goals.map { QCChoiceOption(id: $0.id, title: $0.title) }
        return VStack(alignment: .leading, spacing: 8) {
            QCFieldLabel(text: copy.goalAttach)
            QCChoiceField(label: copy.goalAttach, title: name, options: options, selectedID: goalId) {
                goalId = $0
            }
        }
    }

    private var amountReady: Bool {
        QCLedgerMoney.cents(QCLedgerMoney.solve(amount.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0) > 0
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
        let other = QCLedgerMoney.cents(QCLedgerMoney.solve(otherAmount.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0)
        return other > 0 && !otherCategory.isEmpty
    }

    private var canSave: Bool {
        guard titleReady, amountReady, dateReady, accountReady else { return false }
        if splitOn, entryID == nil { return otherReady }
        return true
    }

    private struct QCEntryMark: UIViewRepresentable {
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

    private func fill(_ existing: QCEntry?) {
        guard !ready else { return }
        ready = true
        if let existing {
            direction = existing.direction
            amount = QCLedgerMoney.fixed(existing.amount, fraction: 2)
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

    private func save(existing: QCEntry?) {
        guard canSave, let value = QCLedgerMoney.solve(amount.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
        let named = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstID = existing?.id ?? QCLedgerID.make()
        let splitting = splitOn && existing == nil
        let entry = QCEntry(
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
        if splitting, let other = QCLedgerMoney.solve(otherAmount.trimmingCharacters(in: .whitespacesAndNewlines)) {
            var second = stored
            second.id = QCLedgerID.make()
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
