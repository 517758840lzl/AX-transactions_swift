//
//  QCBookStoreLedger.swift
//  transaction
//
//  Created by Lzl on 2026/10/7.
//

import Foundation

extension QCBookStore {
    func upsertAccount(_ account: QCAccount) {
        if let index = book.accounts.firstIndex(where: { $0.id == account.id }) {
            book.accounts[index] = account
            book.entries = book.entries.map { entry in
                guard entry.accountId == account.id else { return entry }
                var next = entry
                next.accountName = account.name
                return next
            }
        } else {
            book.accounts.append(account)
        }
        persist()
    }

    func removeAccount(_ id: String) {
        let owned = book.entries.filter { $0.accountId == id }
        var gone = Set(owned.map(\.id))
        for entry in owned {
            if let mate = Self.transferMate(entry.id) { gone.insert(mate) }
        }
        let today = QCLedgerDay.today()
        for entry in book.entries where gone.contains(entry.id) {
            book.removed.insert(QCRemovedEntry(entry: entry, removedOn: today), at: 0)
        }
        book.entries.removeAll { gone.contains($0.id) }
        book.accounts.removeAll { $0.id == id }
        book.repeats.removeAll { $0.accountId == id }
        persist()
    }

    /// transfer-{stamp}-in pairs with transfer-{stamp}-out.
    private static func transferMate(_ id: String) -> String? {
        guard id.hasPrefix("transfer-") else { return nil }
        if id.hasSuffix("-in") { return String(id.dropLast(3)) + "-out" }
        if id.hasSuffix("-out") { return String(id.dropLast(4)) + "-in" }
        return nil
    }

    @discardableResult
    func saveEntry(_ entry: QCEntry) -> QCEntry {
        var next = entry
        if let account = book.accounts.first(where: { $0.id == next.accountId }) {
            next.accountName = account.name
        }
        next.amount = QCLedgerMoney.cents(next.amount)
        if let index = book.entries.firstIndex(where: { $0.id == next.id }) {
            book.entries[index] = next
        } else {
            book.entries.insert(next, at: 0)
        }
        persist()
        return next
    }

    func deleteEntry(_ id: String) {
        if let entry = book.entries.first(where: { $0.id == id }) {
            book.removed.insert(QCRemovedEntry(entry: entry, removedOn: QCLedgerDay.today()), at: 0)
        }
        book.entries.removeAll { $0.id == id }
        persist()
    }

    func restoreEntry(_ id: String) {
        guard let item = book.removed.first(where: { $0.id == id }) else { return }
        book.removed.removeAll { $0.id == id }
        if !book.entries.contains(where: { $0.id == item.entry.id }) {
            book.entries.insert(item.entry, at: 0)
        }
        persist()
    }

    func purgeRemoved(now: Date = Date()) {
        let cutoff = QCLedgerDay.adding(days: -7, to: QCLedgerDay.today(now))
        let kept = book.removed.filter { $0.removedOn >= cutoff }
        guard kept.count != book.removed.count else { return }
        book.removed = kept
        persist()
    }

    func refund(_ source: QCEntry) {
        guard source.isOut, source.refundOf.isEmpty else { return }
        guard !book.entries.contains(where: { $0.refundOf == source.id }) else { return }
        let back = QCEntry(
            id: "refund-\(source.id)",
            title: copy.refundBack(source.title),
            amount: source.amount,
            direction: .income,
            category: source.category,
            date: QCLedgerDay.today(),
            accountName: source.accountName,
            accountId: source.accountId,
            checked: true,
            shared: source.shared,
            countsInBudget: false,
            claim: .none,
            refundOf: source.id
        )
        saveEntry(back)
    }

    func depositTowardGoal(_ goal: QCSavingGoal, from: QCAccount, to: QCAccount, amount: Double, date: String) {
        let value = QCLedgerMoney.cents(amount)
        guard value > 0, from.id != to.id else { return }
        let stamp = QCLedgerID.make()
        let incoming = QCEntry(
            id: "transfer-\(stamp)-in",
            title: "\(copy.transferFrom) \(from.name)",
            amount: value,
            direction: .income,
            category: copy.transferCategory,
            date: date,
            accountName: to.name,
            accountId: to.id,
            checked: true,
            shared: false,
            countsInBudget: false,
            claim: .none
        )
        let outgoing = QCEntry(
            id: "transfer-\(stamp)-out",
            title: goal.title,
            amount: value,
            direction: .out,
            category: copy.transferCategory,
            date: date,
            accountName: from.name,
            accountId: from.id,
            checked: true,
            shared: false,
            countsInBudget: false,
            claim: .none,
            goalId: goal.id
        )
        book.entries.insert(contentsOf: [incoming, outgoing], at: 0)
        persist()
    }

    func toggleChecked(_ id: String) {
        guard let index = book.entries.firstIndex(where: { $0.id == id }) else { return }
        book.entries[index].checked.toggle()
        persist()
    }

    func markReviewed(_ ids: [String]) {
        let set = Set(ids)
        book.entries = book.entries.map { entry in
            guard set.contains(entry.id) else { return entry }
            var next = entry
            next.checked = true
            return next
        }
        persist()
    }

    func addTransfer(from: QCAccount, to: QCAccount, amount: Double, date: String) {
        let value = QCLedgerMoney.cents(amount)
        let stamp = QCLedgerID.make()
        let copy = self.copy
        let incoming = QCEntry(
            id: "transfer-\(stamp)-in",
            title: "\(copy.transferFrom) \(from.name)",
            amount: value,
            direction: .income,
            category: copy.transferCategory,
            date: date,
            accountName: to.name,
            accountId: to.id,
            checked: true,
            shared: false,
            countsInBudget: false,
            claim: .none
        )
        let outgoing = QCEntry(
            id: "transfer-\(stamp)-out",
            title: "\(copy.transferTo) \(to.name)",
            amount: value,
            direction: .out,
            category: copy.transferCategory,
            date: date,
            accountName: from.name,
            accountId: from.id,
            checked: true,
            shared: false,
            countsInBudget: false,
            claim: .none
        )
        book.entries.insert(contentsOf: [incoming, outgoing], at: 0)
        persist()
    }

    func saveRepeat(_ plan: QCRepeatPlan) {
        var next = plan
        next.day = min(max(next.day, 1), 28)
        next.amount = QCLedgerMoney.cents(next.amount)
        if let index = book.repeats.firstIndex(where: { $0.id == next.id }) {
            book.repeats[index] = next
        } else {
            book.repeats.append(next)
        }
        persist()
        settleRepeats()
    }

    func saveGoal(_ goal: QCSavingGoal) {
        var next = goal
        next.target = QCLedgerMoney.cents(max(next.target, 0))
        next.saved = QCLedgerMoney.cents(max(next.saved, 0))
        if let index = book.goals.firstIndex(where: { $0.id == next.id }) {
            book.goals[index] = next
        } else {
            book.goals.append(next)
        }
        persist()
    }

    func deleteGoal(_ id: String) {
        book.goals.removeAll { $0.id == id }
        persist()
    }

    func saveSpark(_ spark: QCSpark) {
        let body = String(spark.body.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2000))
        guard !body.isEmpty else { return }
        let next = QCSpark(
            id: spark.id,
            body: body,
            writtenOn: spark.writtenOn,
            kind: spark.kind,
            tags: QCSparkTags.parse(spark.tags.joined(separator: " ")),
            favorite: spark.favorite,
            image: spark.image
        )
        if let index = book.sparks.firstIndex(where: { $0.id == next.id }) {
            book.sparks[index] = next
        } else {
            book.sparks.append(next)
        }
        persist()
    }

    func deleteSpark(_ id: String) {
        book.sparks.removeAll { $0.id == id }
        persist()
    }

    func payClaim(_ id: String) {
        guard let index = book.entries.firstIndex(where: { $0.id == id }), book.entries[index].claim == .waiting else { return }
        var source = book.entries[index]
        source.claim = .done
        book.entries[index] = source
        let backID = "claim-\(id)"
        if !book.entries.contains(where: { $0.id == backID }) {
            book.entries.insert(QCEntry(
                id: backID,
                title: copy.claimBack(source.title),
                amount: source.amount,
                direction: .income,
                category: source.category,
                date: QCLedgerDay.today(),
                accountName: source.accountName,
                accountId: source.accountId,
                checked: true,
                shared: source.shared,
                countsInBudget: false,
                claim: .none
            ), at: 0)
        }
        persist()
    }

    func deleteRepeat(_ id: String) {
        book.repeats.removeAll { $0.id == id }
        persist()
    }

    func settleRepeats(now: Date = Date()) {
        let month = QCLedgerDay.yearMonth(now)
        let day = Calendar.current.component(.day, from: now)
        var changed = false
        for index in book.repeats.indices {
            var plan = book.repeats[index]
            guard day >= plan.day, plan.lastMonth != month else { continue }
            let id = "repeat-\(plan.id)-\(month)"
            if book.entries.contains(where: { $0.id == id }) {
                plan.lastMonth = month
                book.repeats[index] = plan
                changed = true
                continue
            }
            guard let account = book.accounts.first(where: { $0.id == plan.accountId }) else { continue }
            let stamp = String(format: "%@-%02d", month, plan.day)
            book.entries.insert(QCEntry(
                id: id,
                title: plan.title,
                amount: plan.amount,
                direction: plan.direction,
                category: plan.category,
                date: stamp,
                accountName: account.name,
                accountId: account.id,
                checked: true,
                shared: plan.shared,
                countsInBudget: plan.countsInBudget,
                claim: .none
            ), at: 0)
            plan.lastMonth = month
            book.repeats[index] = plan
            changed = true
        }
        if changed { persist() }
    }

    func importDocument(_ raw: String) -> Bool {
        guard var parsed = QCBookDocument.decode(raw) else { return false }
        _ = QCCategoryMarks.adopt(&parsed)
        book = parsed
        persist()
        return true
    }

    func exportText() -> String {
        QCBookDocument.encode(book, pretty: true)
    }
}
