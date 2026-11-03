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
    @Published var book: Book
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
                    && book.entries.map(\.id) == seeded.entries.map(\.id)
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
        let adopted = CategoryMarks.adopt(&book)
        let labeled = Self.labelSamples(&book)
        let store = BookStore(book: book, fileURL: fileURL)
        if shortened || adopted || labeled || !FileManager.default.fileExists(atPath: fileURL.path) {
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
        Self.labelSamples(&book)
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

    func setDailyReminder(_ on: Bool) {
        guard book.dailyReminder != on else { return }
        book.dailyReminder = on
        persist()
        DailyReminder.shared.sync(book, ask: on)
    }

    func setReminderTime(hour: Int, minute: Int) {
        let nextHour = min(max(hour, 0), 23)
        let nextMinute = min(max(minute, 0), 59)
        guard book.reminderHour != nextHour || book.reminderMinute != nextMinute else { return }
        book.reminderHour = nextHour
        book.reminderMinute = nextMinute
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

    func addCategory(_ name: String, mark: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !book.categories.contains(trimmed) else { return }
        book.categories.append(trimmed)
        if mark != "tag" {
            book.categoryMarks[trimmed] = mark
        }
        persist()
        flash(copy.categoryAdded(trimmed))
    }

    func removeCategory(_ name: String) {
        guard book.categories.count > 1, let fallback = book.categories.first(where: { $0 != name }) else { return }
        book.categories.removeAll { $0 == name }
        book.categoryMarks[name] = nil
        book.categoryCaps[name] = nil
        book.entries = book.entries.map { entry in
            var next = entry
            if next.category == name { next.category = fallback }
            return next
        }
        persist()
    }

    func clearSample() {
        clearBook()
        flash(copy.clearBookDone)
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

    func persist() {
        let hasOwn = book.entries.contains { !$0.id.hasPrefix("sample-") } || book.accounts.contains { !$0.id.hasPrefix("sample-") }
        if hasOwn {
            book.entries.removeAll { $0.id.hasPrefix("sample-") }
            book.accounts.removeAll { $0.id.hasPrefix("sample-") }
            book.sampleCleared = true
        }
        let text = BookDocument.encode(book)
        try? text.write(to: fileURL, atomically: true, encoding: .utf8)
        BillReminder.shared.refresh(book: book)
        DailyReminder.shared.sync(book, ask: false)
    }

    @discardableResult
    static func labelSamples(_ book: inout Book) -> Bool {
        guard !book.sampleCleared else { return false }
        var changed = false
        for index in book.entries.indices {
            let entry = book.entries[index]
            guard entry.id.hasPrefix("sample-") else { continue }
            let title = SampleBook.displayTitle(id: entry.id, title: entry.title, locale: book.locale)
            guard title != entry.title else { continue }
            book.entries[index].title = title
            changed = true
        }
        return changed
    }

    private static func onlySample(_ book: Book) -> Bool {
        !book.sampleCleared
            && !book.entries.isEmpty
            && book.entries.allSatisfy { $0.id.hasPrefix("sample-") }
            && book.accounts.allSatisfy { $0.id.hasPrefix("sample-") }
    }
}
