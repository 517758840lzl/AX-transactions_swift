//
//  AccountEditPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/21.
//

import Combine
import SwiftUI

struct AccountFormView: View {
    @ObservedObject var store: BookStore
    var accountID: String?
    var chooseKind: Bool
    @Environment(\.pageBack) private var pageBack
    @State private var name: String
    @State private var opening: String
    @State private var kind: AccountKind?
    @State private var countsInWorth: Bool
    @State private var archived: Bool
    @State private var statementDay: String
    @State private var dueDay: String
    @State private var ready: Bool

    init(store: BookStore, accountID: String?, chooseKind: Bool) {
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
        FormPage(title: editing ? copy.editAccount : copy.newAccount, back: copy.back) {
            FieldLabel(text: copy.accountName)
            LedgerField(text: $name, placeholder: copy.accountNamePh)
            FieldLabel(text: copy.accountKindLabel)
            ChoiceRow(labels: AccountKind.order.map { copy.accountKind($0) }, index: kind.flatMap { AccountKind.order.firstIndex(of: $0) } ?? -1) { index in
                withAnimation(LedgerScreen.fold) {
                    kind = AccountKind.order[index]
                }
            }
            FieldLabel(text: copy.accountBalance)
            LedgerField(text: $opening, placeholder: "0.00", decimal: true)
            if kind == .card {
                VStack(alignment: .leading, spacing: 14) {
                    FieldLabel(text: copy.cardStatementDay)
                    LedgerField(text: $statementDay, placeholder: "1–28", decimal: true)
                    FieldLabel(text: copy.cardDueDay)
                    LedgerField(text: $dueDay, placeholder: "1–28", decimal: true)
                }
                .transition(.opacity)
            }
            Button { countsInWorth.toggle() } label: {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(countsInWorth ? Palette.pink : Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(countsInWorth ? Palette.pink : Palette.line, lineWidth: 1.5))
                        .overlay {
                            if countsInWorth {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Palette.ink)
                            }
                        }
                        .frame(width: 22, height: 22)
                    Text(copy.countWorth)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                }
            }
            .buttonStyle(.plain)
            PillButton(title: copy.save, enabled: canSave) { save(archived: archived) }
            if editing {
                PillButton(title: archived ? copy.restoreAccount : copy.archiveAccount, filled: false) {
                    save(archived: !archived)
                }
                Button(copy.deleteAccount) {
                    if let accountID { store.removeAccount(accountID) }
                    pageBack()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.review)
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
            opening = LedgerMoney.fixed(account.opening, fraction: 2)
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
        store.upsertAccount(Account(
            id: accountID ?? LedgerID.make(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            opening: LedgerMoney.cents(value),
            kind: kind,
            countsInWorth: countsInWorth,
            archived: nextArchived,
            statementDay: kind == .card ? cycleDay(statementDay) : 0,
            dueDay: kind == .card ? cycleDay(dueDay) : 0
        ))
        pageBack()
    }
}
