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
    /// nil until the iPhone's iCloud sign-in has been checked.
    @Published var cloudOn: Bool?
    @Published var cloudWhen: Date?

    private let database: BookDatabase
    private let legacyURL: URL
    private var noteTask: Task<Void, Never>?
    private var uploadTask: Task<Void, Never>?
    private var uploadChain: Task<Date?, Never>?
    private var cloudReady = false
    private var cloudEpoch = 0

    init(book: Book, database: BookDatabase, legacyURL: URL) {
        self.book = book
        self.database = database
        self.legacyURL = legacyURL
    }

    static func open() -> BookStore {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let folder = directory.appendingPathComponent(BundleTitle.current, isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let legacyURL = folder.appendingPathComponent("ledger-book-v1.json")
        let database = BookDatabase(url: folder.appendingPathComponent("ledger.sqlite"))
        var book: Book
        var shortened = false
        var carried = false
        if let stored = database.load() {
            book = stored
            try? FileManager.default.removeItem(at: legacyURL)
        } else if let raw = try? String(contentsOf: legacyURL, encoding: .utf8), let decoded = BookDocument.decode(raw) {
            book = decoded
            carried = true
        } else {
            book = Book.empty()
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
        let adopted = CategoryMarks.adopt(&book)
        let labeled = Self.labelSamples(&book)
        let sparked = Self.placeSparkRows(&book)
        let store = BookStore(book: book, database: database, legacyURL: legacyURL)
        if shortened || adopted || labeled || carried || sparked {
            store.persist()
        }
        store.settleRepeats()
        store.purgeRemoved()
        store.startCloud()
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
            try? BookDocument.encode(book).write(to: legacyURL, atomically: true, encoding: .utf8)
        }
        BillReminder.shared.refresh(book: book)
        DailyReminder.shared.sync(book, ask: false)
        if cloudReady, hasUserRecords(book) {
            scheduleUpload()
        }
    }

    func refreshCloud() {
        Task { [weak self] in
            guard let self else { return }
            let stamp = await BookCloud.stamp()
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
        let copied = await Task.detached { BookCloud.read(into: temp) }.value
        defer { try? FileManager.default.removeItem(at: temp) }
        guard copied, epoch == cloudEpoch else { return false }
        let loaded: Book? = {
            let incoming = BookDatabase(url: temp)
            return incoming.load()
        }()
        guard let loaded, database.replace(loaded) else { return false }
        book = loaded
        BillReminder.shared.refresh(book: book)
        DailyReminder.shared.sync(book, ask: false)
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
            let stamp = await BookCloud.stamp()
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
            let date = BookCloud.write(temp)
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

    private func hasUserRecords(_ book: Book) -> Bool {
        !book.entries.isEmpty
            || !book.accounts.isEmpty
            || !book.sparks.isEmpty
            || !book.goals.isEmpty
            || !book.removed.isEmpty
            || !book.repeats.isEmpty
    }

    @discardableResult
    /// One pass of ten ledger notes, so an empty inspiration list can be opened.
    private static func placeSparkRows(_ book: inout Book) -> Bool {
        let key = "sparkRowsPlaced"
        guard book.sparks.isEmpty, !UserDefaults.standard.bool(forKey: key) else { return false }
        let today = LedgerDay.today()
        let rows: [(String, SparkKind, [String], Bool, Int)] = [
            ("午饭 28，记在餐饮", .idea, ["餐饮"], false, 0),
            ("地铁来回 6 块", .diary, ["交通"], false, 0),
            ("这杯咖啡 22，值不值", .thought, ["餐饮"], true, 1),
            ("今天出去 86，最多是午饭", .summary, ["餐饮"], false, 1),
            ("订阅 15，想单独记一笔", .idea, ["订阅"], false, 2),
            ("超市买菜 63", .diary, ["日用"], false, 2),
            ("周末那顿 128，最不该花", .thought, ["餐饮"], true, 3),
            ("这三天吃饭占了一半", .summary, ["餐饮"], false, 3),
            ("话费扣了 39", .diary, ["通讯"], false, 4),
            ("下月房租 3200，先记上", .idea, ["居住"], false, 5),
        ]
        book.sparks = rows.enumerated().map { index, row in
            Spark(
                id: "preview-spark-\(index + 1)",
                body: row.0,
                writtenOn: LedgerDay.adding(days: -row.4, to: today),
                kind: row.1,
                tags: row.2,
                favorite: row.3
            )
        }
        UserDefaults.standard.set(true, forKey: key)
        return true
    }

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
}
