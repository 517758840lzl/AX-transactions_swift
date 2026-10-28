//
//  SavingGoalPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/28.
//

import Combine
import SwiftUI

struct SavingGoalsListView: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen

    var body: some View {
        let copy = store.copy
        FormPage(title: copy.savingGoals, back: copy.back) {
            PillButton(title: copy.add) { screen.open(.savingGoal(id: nil)) }
            ForEach(store.book.goals) { goal in
                let kept = BookMath.goalKept(goal, entries: store.book.entries)
                Button { screen.open(.savingGoal(id: goal.id)) } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(goal.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Palette.ink)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            MoneyText(value: kept, mark: store.book.mark, size: 14)
                            Text("/")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Palette.muted)
                            MoneyText(value: goal.target, mark: store.book.mark, size: 14, color: Palette.muted)
                        }
                        GeometryReader { proxy in
                            let ratio = goal.target > 0 ? min(kept / goal.target, 1) : 0
                            ZStack(alignment: .leading) {
                                Capsule().fill(Palette.wash)
                                Capsule().fill(Palette.pink).frame(width: proxy.size.width * ratio)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct SavingGoalFormView: View {
    @ObservedObject var store: BookStore
    var goalID: String?
    @Environment(\.pageBack) private var pageBack
    @State private var title = ""
    @State private var target = ""
    @State private var saved = ""
    @State private var depositAmount = ""
    @State private var fromID = ""
    @State private var toID = ""
    @State private var depositDate = LedgerDay.today()
    @State private var ready = false

    var body: some View {
        let copy = store.copy
        let existing = store.book.goals.first { $0.id == goalID }
        FormPage(title: copy.savingGoals, back: copy.back) {
            FieldLabel(text: copy.name)
            LedgerField(text: $title, placeholder: copy.namePh)
            FieldLabel(text: copy.savingTarget)
            LedgerField(text: $target, placeholder: "0.00", decimal: true)
            FieldLabel(text: copy.savingSaved)
            LedgerField(text: $saved, placeholder: "0.00", decimal: true)
            if let existing {
                let kept = BookMath.goalKept(existing, entries: store.book.entries)
                HStack {
                    Text(copy.goalAttach)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.muted)
                    Spacer()
                    MoneyText(value: kept, mark: store.book.mark, size: 15, color: Palette.ink)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Palette.wash, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            PillButton(title: copy.save, enabled: canSave) { save(existing: existing) }
            if let existing, store.openAccounts().count >= 2 {
                depositBox(copy, goal: existing)
            }
            if existing != nil {
                Button(copy.deleteEntry) {
                    if let goalID { store.deleteGoal(goalID) }
                    pageBack()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.down)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { fill(existing) }
    }

    private var canSave: Bool {
        let goal = Double(target.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && goal > 0
    }

    private func fill(_ existing: SavingGoal?) {
        guard !ready else { return }
        ready = true
        guard let existing else { return }
        title = existing.title
        target = LedgerMoney.fixed(existing.target, fraction: 2)
        saved = LedgerMoney.fixed(existing.saved, fraction: 2)
        let accounts = store.openAccounts()
        fromID = accounts.first?.id ?? ""
        toID = accounts.dropFirst().first?.id ?? ""
    }

    private func depositBox(_ copy: LedgerCopy, goal: SavingGoal) -> some View {
        let accounts = store.openAccounts()
        let fromName = accounts.first { $0.id == fromID }?.name ?? ""
        let toName = accounts.first { $0.id == toID }?.name ?? ""
        let fromOptions = accounts.map { ChoiceOption(id: $0.id, title: $0.name) }
        let toOptions = accounts.filter { $0.id != fromID }.map { ChoiceOption(id: $0.id, title: $0.name) }
        let amount = LedgerMoney.solve(depositAmount.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        return PanelCard(title: copy.goalDeposit, titleSize: 15, card: true) {
            LedgerField(text: $depositAmount, placeholder: "0.00", decimal: true)
            FieldLabel(text: copy.goalFrom)
            ChoiceField(label: copy.goalFrom, title: fromName, options: fromOptions, selectedID: fromID) { picked in
                fromID = picked
                if toID == picked { toID = accounts.first { $0.id != picked }?.id ?? "" }
            }
            FieldLabel(text: copy.goalTo)
            ChoiceField(label: copy.goalTo, title: toName, options: toOptions, selectedID: toID) { toID = $0 }
            FieldLabel(text: copy.date)
            DateField(copy: copy, iso: $depositDate, label: copy.date)
            PillButton(title: copy.goalDeposit, enabled: amount > 0 && fromID != toID && !toID.isEmpty) {
                guard let from = accounts.first(where: { $0.id == fromID }),
                      let to = accounts.first(where: { $0.id == toID }) else { return }
                store.depositTowardGoal(goal, from: from, to: to, amount: amount, date: depositDate)
                depositAmount = ""
            }
        }
    }

    private func save(existing: SavingGoal?) {
        guard canSave, let goal = Double(target.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
        let kept = Double(saved.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        store.saveGoal(SavingGoal(
            id: existing?.id ?? LedgerID.make(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            target: goal,
            saved: kept
        ))
        pageBack()
    }
}
