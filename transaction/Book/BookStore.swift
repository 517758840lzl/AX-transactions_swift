//
//  BookStore.swift
//  transaction
//
//  Created by Lzl on 2026/10/7.
//

import Combine
import Foundation

enum BundleTitle {
    /// Display name from the target, then the product name, then the bundle file name.
    static var current: String {
        let bundle = Bundle.main
        let display = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        let product = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
        let raw = [display, product]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
            ?? bundle.bundleURL.deletingPathExtension().lastPathComponent
        let cleaned = raw.replacingOccurrences(of: "/", with: "")
        if !cleaned.isEmpty { return cleaned }
        return bundle.bundleURL.deletingPathExtension().lastPathComponent
    }
}

final class BookStore: ObservableObject {
    @Published private(set) var book: Book
    @Published var note: String?

    private let fileURL: URL
    private var noteTask: Task<Void, Never>?

    init(book: Book, fileURL: URL) {
        self.book = book
        self.fileURL = fileURL
    }

    static func open() -> BookStore {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let folder = directory.appendingPathComponent(BundleTitle.current, isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let fileURL = folder.appendingPathComponent("ledger-book-v1.json")
        var book: Book
        var shortened = false
        if let raw = try? String(contentsOf: fileURL, encoding: .utf8), let decoded = BookDocument.decode(raw) {
            book = decoded
            if Self.onlySample(book) {
                let seeded = SampleBook.seed()
                let same = book.categories == seeded.categories
                    && book.accounts.map(\.name) == seeded.accounts.map(\.name)
                    && book.entries.map(\.title) == seeded.entries.map(\.title)
                    && book.entries.count == seeded.entries.count
                if !same {
                    book.accounts = seeded.accounts
                    book.entries = seeded.entries
                    book.categories = seeded.categories
                    shortened = true
                }
            }
        } else {
            book = SampleBook.seed()
        }
        let store = BookStore(book: book, fileURL: fileURL)
        if shortened || !FileManager.default.fileExists(atPath: fileURL.path) {
            store.persist()
        }
        store.settleRepeats()
        store.purgeRemoved()
        return store
    }

    func openAccounts(keeping id: String = "") -> [Account] {
        book.accounts.filter { !$0.archived || $0.id == id }
    }

    var copy: LedgerCopy { LedgerCopy.resolve(book.locale) }

    func flash(_ message: String) {
        note = message
        noteTask?.cancel()
        noteTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.note = nil
        }
    }

    func replace(_ book: Book) {
        self.book = book
        persist()
    }

    func setLocale(_ locale: BookLocale) {
        guard book.locale != locale else { return }
        book.locale = locale
        persist()
    }

    func setHideAmounts(_ hidden: Bool) {
        guard book.hideAmounts != hidden else { return }
        book.hideAmounts = hidden
        persist()
    }

    func setCurrency(_ currency: CurrencyCode) {
        guard book.currency != currency else { return }
        book.currency = currency
        persist()
    }

    func saveProfile(nickname: String, gender: Gender) {
        let trimmed = String(nickname.trimmingCharacters(in: .whitespacesAndNewlines).prefix(12))
        guard !trimmed.isEmpty else { return }
        book.nickname = trimmed
        book.gender = gender
        persist()
    }

    func saveBudget(monthly: Double?, caps: [String: Double], clear: Bool) {
        if clear {
            book.monthlyBudget = nil
            book.categoryCaps = [:]
        } else {
            book.monthlyBudget = monthly
            book.categoryCaps = caps
        }
        persist()
    }

    func addCategory(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !book.categories.contains(trimmed) else { return }
        book.categories.append(trimmed)
        persist()
        flash(copy.categoryAdded(trimmed))
    }

    func removeCategory(_ name: String) {
        guard book.categories.count > 1, let fallback = book.categories.first(where: { $0 != name }) else { return }
        book.categories.removeAll { $0 == name }
        book.categoryCaps[name] = nil
        book.entries = book.entries.map { entry in
            var next = entry
            if next.category == name { next.category = fallback }
            return next
        }
        persist()
    }

    func upsertAccount(_ account: Account) {
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
        let today = LedgerDay.today()
        for entry in book.entries where gone.contains(entry.id) {
            book.removed.insert(RemovedEntry(entry: entry, removedOn: today), at: 0)
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
    func saveEntry(_ entry: Entry, creatingCashNamed name: String?) -> Entry {
        var next = entry
        if next.accountId.isEmpty {
            let account = Account(
                id: LedgerID.make(),
                name: (name?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? copy.accountKindCash,
                opening: 0,
                kind: .cash,
                countsInWorth: true
            )
            book.accounts.append(account)
            next.accountId = account.id
            next.accountName = account.name
        } else if let account = book.accounts.first(where: { $0.id == next.accountId }) {
            next.accountName = account.name
        }
        next.amount = LedgerMoney.cents(next.amount)
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
            book.removed.insert(RemovedEntry(entry: entry, removedOn: LedgerDay.today()), at: 0)
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
        let cutoff = LedgerDay.adding(days: -7, to: LedgerDay.today(now))
        let kept = book.removed.filter { $0.removedOn >= cutoff }
        guard kept.count != book.removed.count else { return }
        book.removed = kept
        persist()
    }

    func refund(_ source: Entry) {
        guard source.isOut, source.refundOf.isEmpty else { return }
        guard !book.entries.contains(where: { $0.refundOf == source.id }) else { return }
        let back = Entry(
            id: "refund-\(source.id)",
            title: copy.refundBack(source.title),
            amount: source.amount,
            direction: .income,
            category: source.category,
            date: LedgerDay.today(),
            accountName: source.accountName,
            accountId: source.accountId,
            checked: true,
            shared: source.shared,
            countsInBudget: false,
            claim: .none,
            refundOf: source.id
        )
        saveEntry(back, creatingCashNamed: nil)
    }

    func depositTowardGoal(_ goal: SavingGoal, from: Account, to: Account, amount: Double, date: String) {
        let value = LedgerMoney.cents(amount)
        guard value > 0, from.id != to.id else { return }
        let stamp = LedgerID.make()
        let incoming = Entry(
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
        let outgoing = Entry(
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

    func addTransfer(from: Account, to: Account, amount: Double, date: String) {
        let value = LedgerMoney.cents(amount)
        let stamp = LedgerID.make()
        let copy = self.copy
        let incoming = Entry(
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
        let outgoing = Entry(
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

    func clearSample() {
        clearBook()
        flash(copy.clearBookDone)
    }

    private static func onlySample(_ book: Book) -> Bool {
        !book.sampleCleared
            && !book.accounts.isEmpty
            && !book.entries.isEmpty
            && book.accounts.allSatisfy { $0.id.hasPrefix("sample-") }
            && book.entries.allSatisfy { $0.id.hasPrefix("sample-") }
    }

    func clearBook() {
        book.entries = []
        book.accounts = []
        book.templates = []
        book.monthlyBudget = nil
        book.categoryCaps = [:]
        book.repeats = []
        book.goals = []
        book.removed = []
        book.sampleCleared = true
        persist()
    }

    func saveRepeat(_ plan: RepeatPlan) {
        var next = plan
        next.day = min(max(next.day, 1), 28)
        next.amount = LedgerMoney.cents(next.amount)
        if let index = book.repeats.firstIndex(where: { $0.id == next.id }) {
            book.repeats[index] = next
        } else {
            book.repeats.append(next)
        }
        persist()
        settleRepeats()
    }

    func saveGoal(_ goal: SavingGoal) {
        var next = goal
        next.target = LedgerMoney.cents(max(next.target, 0))
        next.saved = LedgerMoney.cents(max(next.saved, 0))
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

    func payClaim(_ id: String) {
        guard let index = book.entries.firstIndex(where: { $0.id == id }), book.entries[index].claim == .waiting else { return }
        var source = book.entries[index]
        source.claim = .done
        book.entries[index] = source
        let backID = "claim-\(id)"
        if !book.entries.contains(where: { $0.id == backID }) {
            book.entries.insert(Entry(
                id: backID,
                title: copy.claimBack(source.title),
                amount: source.amount,
                direction: .income,
                category: source.category,
                date: LedgerDay.today(),
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
        let month = LedgerDay.yearMonth(now)
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
            book.entries.insert(Entry(
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
        guard let parsed = BookDocument.decode(raw) else { return false }
        book = parsed
        persist()
        return true
    }

    func exportText() -> String {
        BookDocument.encode(book, pretty: true)
    }

    private func persist() {
        let text = BookDocument.encode(book)
        try? text.write(to: fileURL, atomically: true, encoding: .utf8)
        BillReminder.shared.refresh(book: book)
    }
}
