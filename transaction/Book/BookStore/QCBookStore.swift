//
//  QCBookStore.swift
//  transaction
//
//  Created by Lzl on 2026/10/7.
//

import Combine
import Foundation

enum QCBundleTitle {
    // O nome vem primeiro do target, depois do nome do produto, por fim do nome do bundle
    // this order is on purpose. target name get localize by system, product name not
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

final class QCBookStore: ObservableObject {
    @Published var book: QCBook
    @Published var note: String?
    /// nil until the iPhone's iCloud sign-in has been checked.
    @Published var cloudOn: Bool?
    @Published var cloudWhen: Date?

    private let database: QCBookDatabase
    private let legacyURL: URL
    private var noteTask: Task<Void, Never>?
    private var uploadTask: Task<Void, Never>?
    private var uploadChain: Task<Date?, Never>?
    private var cloudReady = false
    private var cloudEpoch = 0

    init(book: QCBook, database: QCBookDatabase, legacyURL: URL) {
        self.book = book
        self.database = database
        self.legacyURL = legacyURL
    }

    static func open() -> QCBookStore {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let folder = directory.appendingPathComponent(QCBundleTitle.current, isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let legacyURL = folder.appendingPathComponent("ledger-book-v1.json")
        let database = QCBookDatabase(url: folder.appendingPathComponent("ledger.sqlite"))
        var book: QCBook
        var shortened = false
        var carried = false
        if let stored = database.load() {
            book = stored
            try? FileManager.default.removeItem(at: legacyURL)
        } else if let raw = try? String(contentsOf: legacyURL, encoding: .utf8), let decoded = QCBookDocument.decode(raw) {
            book = decoded
            carried = true
        } else {
            book = QCBook.empty()
            book.sampleCleared = true
            carried = true
        }
        let hadSample = book.entries.contains { $0.id.hasPrefix("sample-") } || book.accounts.contains { $0.id.hasPrefix("sample-") }
        if hadSample {
            book.entries.removeAll { $0.id.hasPrefix("sample-") }
            book.accounts.removeAll { $0.id.hasPrefix("sample-") }
            book.sampleCleared = true
            shortened = true
        }
        if book.sparks.contains(where: { $0.id.hasPrefix("preview-spark-") }) {
            book.sparks.removeAll { $0.id.hasPrefix("preview-spark-") }
            shortened = true
        }
        if !book.accounts.contains(where: { !$0.id.hasPrefix("sample-") }) {
            let copy = QCLedgerCopy.resolve(book.locale)
            book.accounts.append(QCAccount(
                id: QCLedgerID.make(),
                name: copy.accountKindCash,
                opening: 0,
                kind: .cash,
                countsInWorth: true
            ))
            shortened = true
        }
        let adopted = QCCategoryMarks.adopt(&book)
        let labeled = Self.labelSamples(&book)
        let store = QCBookStore(book: book, database: database, legacyURL: legacyURL)
        if shortened || adopted || labeled || carried {
            store.persist()
        }
        store.settleRepeats()
        store.purgeRemoved()
        store.startCloud()
        return store
    }

    func openAccounts(keeping id: String = "") -> [QCAccount] {
        book.accounts.filter { !$0.archived || $0.id == id }
    }

    var copy: QCLedgerCopy { QCLedgerCopy.resolve(book.locale) }

    func flash(_ message: String) {
        note = message
        noteTask?.cancel()
        noteTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.note = nil
        }
    }

    func replace(_ book: QCBook) {
        self.book = book
        persist()
    }

    func setLocale(_ locale: QCBookLocale) {
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

    func setCurrency(_ currency: QCCurrencyCode) {
        guard book.currency != currency else { return }
        book.currency = currency
        persist()
    }

    func setDailyReminder(_ on: Bool) {
        guard book.dailyReminder != on else { return }
        book.dailyReminder = on
        persist()
        QCDailyReminder.shared.sync(book, ask: on)
    }

    func setReminderTime(hour: Int, minute: Int) {
        let nextHour = min(max(hour, 0), 23)
        let nextMinute = min(max(minute, 0), 59)
        guard book.reminderHour != nextHour || book.reminderMinute != nextMinute else { return }
        book.reminderHour = nextHour
        book.reminderMinute = nextMinute
        persist()
    }

    func saveProfile(nickname: String, gender: QCGender) {
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
        book.sparks = []
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
        if database.replace(book) {
            try? FileManager.default.removeItem(at: legacyURL)
        } else {
            try? QCBookDocument.encode(book).write(to: legacyURL, atomically: true, encoding: .utf8)
        }
        QCBillReminder.shared.refresh(book: book)
        QCDailyReminder.shared.sync(book, ask: false)
        if cloudReady, hasUserRecords(book) {
            scheduleUpload()
        }
    }

    func refreshCloud() {
        Task { [weak self] in
            guard let self else { return }
            let stamp = await QCBookCloud.stamp()
            cloudOn = stamp.signedIn
            cloudWhen = stamp.savedAt
        }
    }

    func saveToCloud() async -> Bool {
        await uploadBook() != nil
    }

    func bringFromCloud(announce: Bool) async -> Bool {
        cloudEpoch += 1
        let epoch = cloudEpoch
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("ledger-cloud-in-\(UUID().uuidString).sqlite")
        let copied = await Task.detached { QCBookCloud.read(into: temp) }.value
        defer { try? FileManager.default.removeItem(at: temp) }
        guard copied, epoch == cloudEpoch else { return false }
        let loaded: QCBook? = {
            let incoming = QCBookDatabase(url: temp)
            return incoming.load()
        }()
        guard let loaded, database.replace(loaded) else { return false }
        book = loaded
        QCBillReminder.shared.refresh(book: book)
        QCDailyReminder.shared.sync(book, ask: false)
        if announce { flash(copy.cloudBrought) }
        return true
    }

    func cloudClock(_ date: Date) -> String {
        let formatter = DateFormatter()
        let code = book.locale.rawValue == "zh" ? "zh_CN" : book.locale.rawValue
        formatter.locale = Locale(identifier: code)
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func startCloud() {
        Task { [weak self] in
            guard let self else { return }
            let stamp = await QCBookCloud.stamp()
            cloudOn = stamp.signedIn
            cloudWhen = stamp.savedAt
            cloudReady = true
            if stamp.signedIn, hasUserRecords(book) {
                _ = await uploadBook()
            }
        }
    }

    private func scheduleUpload() {
        guard cloudOn == true else { return }
        uploadTask?.cancel()
        uploadTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard let self, !Task.isCancelled else { return }
            _ = await uploadBook()
        }
    }

    private func uploadBook() async -> Date? {
        let previous = uploadChain
        let task = Task { [weak self] () -> Date? in
            _ = await previous?.value
            guard let self else { return nil }
            return await self.writeSnapshot()
        }
        uploadChain = task
        return await task.value
    }

    private func writeSnapshot() async -> Date? {
        let epoch = cloudEpoch
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("ledger-cloud-\(UUID().uuidString).sqlite")
        guard database.snapshot(to: temp) else { return nil }
        guard epoch == cloudEpoch else {
            try? FileManager.default.removeItem(at: temp)
            return nil
        }
        let when = await Task.detached {
            let date = QCBookCloud.write(temp)
            try? FileManager.default.removeItem(at: temp)
            return date
        }.value
        guard epoch == cloudEpoch else { return nil }
        if let when {
            cloudOn = true
            cloudWhen = when
        }
        return when
    }

    private func hasUserRecords(_ book: QCBook) -> Bool {
        !book.entries.isEmpty
            || !book.accounts.isEmpty
            || !book.sparks.isEmpty
            || !book.goals.isEmpty
            || !book.removed.isEmpty
            || !book.repeats.isEmpty
    }

    @discardableResult
    static func labelSamples(_ book: inout QCBook) -> Bool {
        guard !book.sampleCleared else { return false }
        var changed = false
        for index in book.entries.indices {
            let entry = book.entries[index]
            guard entry.id.hasPrefix("sample-") else { continue }
            let title = QCSampleBook.displayTitle(id: entry.id, title: entry.title, locale: book.locale)
            guard title != entry.title else { continue }
            book.entries[index].title = title
            changed = true
        }
        return changed
    }
}
