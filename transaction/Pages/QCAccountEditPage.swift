//
//  QCAccountEditPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/21.
//

import SwiftUI

struct QCAccountFormView: View {
    @ObservedObject var store: QCBookStore
    var accountID: String?
    var chooseKind: Bool
    @Environment(\.pageBack) private var pageBack
    @State private var name: String
    @State private var opening: String
    @State private var kind: QCAccountKind?
    @State private var countsInWorth: Bool
    @State private var archived: Bool
    @State private var statementDay: String
    @State private var dueDay: String
    @State private var ready: Bool

    init(store: QCBookStore, accountID: String?, chooseKind: Bool) {
        self._store = ObservedObject(wrappedValue: store)
        self.accountID = accountID
        self.chooseKind = chooseKind
        _name = State(initialValue: "")
        _opening = State(initialValue: "")
        _kind = State(initialValue: accountID == nil && chooseKind ? nil : .cash)
        _countsInWorth = State(initialValue: true)
        _archived = State(initialValue: false)
        _statementDay = State(initialValue: "")
        _dueDay = State(initialValue: "")
        _ready = State(initialValue: false)
    }

    var body: some View {
        let copy = store.copy
        let editing = store.book.accounts.contains { $0.id == accountID }
        QCFormPage(title: editing ? copy.editAccount : copy.newAccount, back: copy.back, place: "account-form-\(accountID ?? "new")") {
            QCFieldLabel(text: copy.accountName)
            QCLedgerField(text: $name, placeholder: copy.accountNamePh)
            QCFieldLabel(text: copy.accountKindLabel)
            QCChoiceRow(labels: QCAccountKind.order.map { copy.accountKind($0) }, index: kind.flatMap { QCAccountKind.order.firstIndex(of: $0) } ?? -1) { index in
                withAnimation(QCLedgerScreen.fold) {
                    kind = QCAccountKind.order[index]
                }
            }
            QCFieldLabel(text: copy.accountBalance)
            QCLedgerField(text: $opening, placeholder: "0.00", decimal: true)
            if kind == .card {
                VStack(alignment: .leading, spacing: 14) {
                    QCFieldLabel(text: copy.cardStatementDay)
                    QCLedgerField(text: $statementDay, placeholder: "1–28", decimal: true)
                    QCFieldLabel(text: copy.cardDueDay)
                    QCLedgerField(text: $dueDay, placeholder: "1–28", decimal: true)
                }
                .transition(.opacity)
            }
            Button { countsInWorth.toggle() } label: {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(countsInWorth ? QCPalette.pink : Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(countsInWorth ? QCPalette.pink : QCPalette.line, lineWidth: 1.5))
                        .overlay {
                            if countsInWorth {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(QCPalette.ink)
                            }
                        }
                        .frame(width: 22, height: 22)
                    Text(copy.countWorth)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(QCPalette.ink)
                }
            }
            .buttonStyle(.plain)
            QCPillButton(title: copy.save, enabled: canSave) { save(archived: archived) }
            if editing {
                QCPillButton(title: archived ? copy.restoreAccount : copy.archiveAccount, filled: false) {
                    save(archived: !archived)
                }
                Button(copy.deleteAccount) {
                    if let accountID { store.removeAccount(accountID) }
                    pageBack()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(QCPalette.review)
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
            opening = QCLedgerMoney.fixed(account.opening, fraction: 2)
            kind = account.kind
            countsInWorth = account.countsInWorth
            archived = account.archived
            statementDay = account.statementDay > 0 ? String(account.statementDay) : ""
            dueDay = account.dueDay > 0 ? String(account.dueDay) : ""
        }
    }

    private func cycleDay(_ raw: String) -> Int {
        guard let value = Int(raw.trimmingCharacters(in: .whitespacesAndNewlines)), value >= 1 else { return 0 }
        return min(value, 28)
    }

    private var canSave: Bool {
        kind != nil && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && Double(opening.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    private func save(archived nextArchived: Bool) {
        guard canSave, let kind, let value = Double(opening.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
        store.upsertAccount(QCAccount(
            id: accountID ?? QCLedgerID.make(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            opening: QCLedgerMoney.cents(value),
            kind: kind,
            countsInWorth: countsInWorth,
            archived: nextArchived,
            statementDay: kind == .card ? cycleDay(statementDay) : 0,
            dueDay: kind == .card ? cycleDay(dueDay) : 0
        ))
        pageBack()
    }
}
