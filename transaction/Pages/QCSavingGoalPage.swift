//
//  QCSavingGoalPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/28.
//

import SwiftUI

struct QCSavingGoalsListView: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen

    var body: some View {
        let copy = store.copy
        QCFormPage(title: copy.savingGoals, back: copy.back, place: "goals") {
            QCPillButton(title: copy.add) { screen.open(.savingGoal(id: nil)) }
            ForEach(store.book.goals) { goal in
                let kept = QCBookMath.goalKept(goal, entries: store.book.entries)
                Button { screen.open(.savingGoal(id: goal.id)) } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(goal.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(QCPalette.ink)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            QCMoneyText(value: kept, mark: store.book.mark, size: 14)
                            Text("/")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(QCPalette.muted)
                            QCMoneyText(value: goal.target, mark: store.book.mark, size: 14, color: QCPalette.muted)
                        }
                        GeometryReader { proxy in
                            let ratio = goal.target > 0 ? min(kept / goal.target, 1) : 0
                            ZStack(alignment: .leading) {
                                Capsule().fill(QCPalette.wash)
                                Capsule().fill(QCPalette.pink).frame(width: proxy.size.width * ratio)
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

struct QCSavingGoalFormView: View {
    @ObservedObject var store: QCBookStore
    var goalID: String?
    @Environment(\.pageBack) private var pageBack
    @State private var title = ""
    @State private var target = ""
    @State private var saved = ""
    @State private var depositAmount = ""
    @State private var fromID = ""
    @State private var toID = ""
    @State private var depositDate = QCLedgerDay.today()
    @State private var ready = false

    var body: some View {
        let copy = store.copy
        let existing = store.book.goals.first { $0.id == goalID }
        QCFormPage(title: copy.savingGoals, back: copy.back, place: "goal-\(goalID ?? "new")") {
            QCFieldLabel(text: copy.name)
            QCLedgerField(text: $title, placeholder: copy.namePh)
            QCFieldLabel(text: copy.savingTarget)
            QCLedgerField(text: $target, placeholder: "0.00", decimal: true)
            QCFieldLabel(text: copy.savingSaved)
            QCLedgerField(text: $saved, placeholder: "0.00", decimal: true)
            if let existing {
                let kept = QCBookMath.goalKept(existing, entries: store.book.entries)
                HStack {
                    Text(copy.goalAttach)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(QCPalette.muted)
                    Spacer()
                    QCMoneyText(value: kept, mark: store.book.mark, size: 15, color: QCPalette.ink)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(QCPalette.wash, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            QCPillButton(title: copy.save, enabled: canSave) { save(existing: existing) }
            if let existing, store.openAccounts().count >= 2 {
                depositBox(copy, goal: existing)
            }
            if existing != nil {
                Button(copy.deleteEntry) {
                    if let goalID { store.deleteGoal(goalID) }
                    pageBack()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(QCPalette.down)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { fill(existing) }
    }

    private var canSave: Bool {
        let goal = QCLedgerMoney.cents(Double(target.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0)
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && goal > 0
    }

    private func fill(_ existing: QCSavingGoal?) {
        guard !ready else { return }
        ready = true
        guard let existing else { return }
        title = existing.title
        target = QCLedgerMoney.fixed(existing.target, fraction: 2)
        saved = QCLedgerMoney.fixed(existing.saved, fraction: 2)
        let accounts = store.openAccounts()
        fromID = accounts.first?.id ?? ""
        toID = accounts.dropFirst().first?.id ?? ""
    }

    private func depositBox(_ copy: QCLedgerCopy, goal: QCSavingGoal) -> some View {
        let accounts = store.openAccounts()
        let fromName = accounts.first { $0.id == fromID }?.name ?? ""
        let toName = accounts.first { $0.id == toID }?.name ?? ""
        let fromOptions = accounts.map { QCChoiceOption(id: $0.id, title: $0.name) }
        let toOptions = accounts.filter { $0.id != fromID }.map { QCChoiceOption(id: $0.id, title: $0.name) }
        let amount = QCLedgerMoney.solve(depositAmount.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        return QCPanelCard(title: copy.goalDeposit, titleSize: 15, card: true) {
            QCLedgerField(text: $depositAmount, placeholder: "0.00", decimal: true)
            QCFieldLabel(text: copy.goalFrom)
            QCChoiceField(label: copy.goalFrom, title: fromName, options: fromOptions, selectedID: fromID) { picked in
                fromID = picked
                if toID == picked { toID = accounts.first { $0.id != picked }?.id ?? "" }
            }
            QCFieldLabel(text: copy.goalTo)
            QCChoiceField(label: copy.goalTo, title: toName, options: toOptions, selectedID: toID) { toID = $0 }
            QCFieldLabel(text: copy.date)
            QCDateField(copy: copy, iso: $depositDate, label: copy.date)
            QCPillButton(title: copy.goalDeposit, enabled: amount > 0 && fromID != toID && !toID.isEmpty) {
                guard let from = accounts.first(where: { $0.id == fromID }),
                      let to = accounts.first(where: { $0.id == toID }) else { return }
                store.depositTowardGoal(goal, from: from, to: to, amount: amount, date: depositDate)
                depositAmount = ""
            }
        }
    }

    private func save(existing: QCSavingGoal?) {
        guard canSave, let goal = Double(target.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
        let kept = Double(saved.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        store.saveGoal(QCSavingGoal(
            id: existing?.id ?? QCLedgerID.make(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            target: goal,
            saved: kept
        ))
        pageBack()
    }
}
