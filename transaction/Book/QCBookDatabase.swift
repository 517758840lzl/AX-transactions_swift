//
//  QCBookDatabase.swift
//  transaction
//

//  Created by Lzl on 2026/10/18.
//

import Foundation
import SQLite3

// O livro todo é um ficheiro sqlite. A posição do botão de adicionar fica nas preferences
final class QCBookDatabase {
    private var db: OpaquePointer?
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    let ready: Bool

    init(url: URL) {
        var opened: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        let openedOK = sqlite3_open_v2(url.path, &opened, flags, nil) == SQLITE_OK
        db = opened
        ready = openedOK && opened != nil
        guard ready else { return }
        // O busy_timeout tem de ser posto antes de ligar o WAL. Ao contrário, escritas em paralelo dão lock logo. Não perguntem como sei
        sqlite3_busy_timeout(db, 2000)
        _ = exec("PRAGMA journal_mode = WAL")
        // Liga as chaves estrangeiras. Ao apagar uma conta o cascade trata disto, senão era entry a entry
        _ = exec("PRAGMA foreign_keys = ON")
        createTables()
    }

    deinit {
        // Aqui esteve o sqlite3_close_v2. Na prática é igual ao close e ainda obriga a validar o ponteiro outra vez
        // sqlite3_close_v2(db)
        sqlite3_close(db)
    }

    func load() -> QCBook? {
        guard ready else { return nil }
        // A tabela profile tem uma linha só, trazer as colunas todas é mais simples. Ao acrescentar campos, mudar aqui e no create. Já me esqueci
        guard let profile = row("SELECT nickname, gender, locale, currency, monthly, hide_amounts, lock_on_open, daily_reminder, reminder_hour, reminder_minute, sample_cleared, preset_stamp FROM profile WHERE id = 1") else {
            return nil
        }
        var book = QCBook.empty()
        book.nickname = text(profile, 0)
        book.gender = QCGender.read(text(profile, 1))
        book.locale = QCBookLocale.read(text(profile, 2))
        book.currency = QCCurrencyCode.read(text(profile, 3))
        book.monthlyBudget = optionalDouble(profile, 4)
        book.hideAmounts = flag(profile, 5)
        book.lockOnOpen = flag(profile, 6)
        book.dailyReminder = flag(profile, 7)
        book.reminderHour = int(profile, 8)
        book.reminderMinute = int(profile, 9)
        book.sampleCleared = flag(profile, 10)
        book.presetStamp = int(profile, 11)
        sqlite3_finalize(profile)

        let categories = strings("SELECT name FROM categories ORDER BY position")
        if !categories.isEmpty { book.categories = categories }
        book.categoryMarks = pairs("SELECT name, mark FROM marks")
        book.categoryCaps = amounts("SELECT name, amount FROM caps")
        book.accounts = accounts()
        book.entries = entries("SELECT id, title, amount, direction, category, date, account_name, account_id, checked, shared, counts_in_budget, claim, refund_of, goal_id, split_group FROM entries ORDER BY position")
        book.removed = removed()
        book.goals = goals()
        book.repeats = repeats()
        book.templates = templates()
        book.sparks = sparks()
        return book
    }

    @discardableResult
    func replace(_ book: QCBook) -> Bool {
        guard ready, exec("BEGIN IMMEDIATE") else { return false }
        let wrote = write(book)
        if wrote, exec("COMMIT") { return true }
        _ = exec("ROLLBACK")
        return false
    }

    // Uma cópia consistente, blobs das imagens incluídos, com o ficheiro original a continuar em modo WAL
    func snapshot(to url: URL) -> Bool {
        guard let db else { return false }
        try? FileManager.default.removeItem(at: url)
        var dest: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE
        guard sqlite3_open_v2(url.path, &dest, flags, nil) == SQLITE_OK, let dest else { return false }
        defer { sqlite3_close(dest) }
        guard let backup = sqlite3_backup_init(dest, "main", db, "main") else { return false }
        let step = sqlite3_backup_step(backup, -1)
        sqlite3_backup_finish(backup)
        return step == SQLITE_DONE
    }

    private func createTables() {
        let statements = [
            """
            CREATE TABLE IF NOT EXISTS profile (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              nickname TEXT NOT NULL,
              gender TEXT NOT NULL,
              locale TEXT NOT NULL,
              currency TEXT NOT NULL,
              monthly REAL,
              hide_amounts INTEGER NOT NULL,
              lock_on_open INTEGER NOT NULL,
              daily_reminder INTEGER NOT NULL,
              reminder_hour INTEGER NOT NULL,
              reminder_minute INTEGER NOT NULL,
              sample_cleared INTEGER NOT NULL,
              preset_stamp INTEGER NOT NULL
            )
            """,
            "CREATE TABLE IF NOT EXISTS categories (position INTEGER PRIMARY KEY, name TEXT NOT NULL)",
            "CREATE TABLE IF NOT EXISTS marks (name TEXT PRIMARY KEY, mark TEXT NOT NULL)",
            "CREATE TABLE IF NOT EXISTS caps (name TEXT PRIMARY KEY, amount REAL NOT NULL)",
            """
            CREATE TABLE IF NOT EXISTS accounts (
              id TEXT PRIMARY KEY,
              position INTEGER NOT NULL,
              name TEXT NOT NULL,
              opening REAL NOT NULL,
              kind TEXT NOT NULL,
              counts_in_worth INTEGER NOT NULL,
              archived INTEGER NOT NULL,
              statement_day INTEGER NOT NULL,
              due_day INTEGER NOT NULL
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS entries (
              id TEXT PRIMARY KEY,
              position INTEGER NOT NULL,
              title TEXT NOT NULL,
              amount REAL NOT NULL,
              direction TEXT NOT NULL,
              category TEXT NOT NULL,
              date TEXT NOT NULL,
              account_name TEXT NOT NULL,
              account_id TEXT NOT NULL,
              checked INTEGER NOT NULL,
              shared INTEGER NOT NULL,
              counts_in_budget INTEGER NOT NULL,
              claim TEXT NOT NULL,
              refund_of TEXT NOT NULL,
              goal_id TEXT NOT NULL,
              split_group TEXT NOT NULL
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS removed (
              id TEXT PRIMARY KEY,
              position INTEGER NOT NULL,
              removed_on TEXT NOT NULL,
              title TEXT NOT NULL,
              amount REAL NOT NULL,
              direction TEXT NOT NULL,
              category TEXT NOT NULL,
              date TEXT NOT NULL,
              account_name TEXT NOT NULL,
              account_id TEXT NOT NULL,
              checked INTEGER NOT NULL,
              shared INTEGER NOT NULL,
              counts_in_budget INTEGER NOT NULL,
              claim TEXT NOT NULL,
              refund_of TEXT NOT NULL,
              goal_id TEXT NOT NULL,
              split_group TEXT NOT NULL
            )
            """,
            "CREATE TABLE IF NOT EXISTS goals (id TEXT PRIMARY KEY, position INTEGER NOT NULL, title TEXT NOT NULL, target REAL NOT NULL, saved REAL NOT NULL)",
            """
            CREATE TABLE IF NOT EXISTS repeats (
              id TEXT PRIMARY KEY,
              position INTEGER NOT NULL,
              title TEXT NOT NULL,
              amount REAL NOT NULL,
              direction TEXT NOT NULL,
              category TEXT NOT NULL,
              account_id TEXT NOT NULL,
              shared INTEGER NOT NULL,
              counts_in_budget INTEGER NOT NULL,
              day INTEGER NOT NULL,
              last_month TEXT NOT NULL
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS templates (
              id TEXT PRIMARY KEY,
              position INTEGER NOT NULL,
              title TEXT NOT NULL,
              amount REAL NOT NULL,
              direction TEXT NOT NULL,
              category TEXT NOT NULL,
              account_id TEXT NOT NULL,
              shared INTEGER NOT NULL
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS sparks (
              id TEXT PRIMARY KEY,
              position INTEGER NOT NULL,
              body TEXT NOT NULL,
              written_on TEXT NOT NULL,
              kind TEXT NOT NULL DEFAULT 'idea',
              tags TEXT NOT NULL DEFAULT '',
              favorite INTEGER NOT NULL DEFAULT 0,
              image BLOB
            )
            """,
            "CREATE INDEX IF NOT EXISTS entries_date ON entries(date)",
            "CREATE INDEX IF NOT EXISTS entries_account ON entries(account_id)",
        ]
        for sql in statements { _ = exec(sql) }
        widenSparks()
    }

    private func widenSparks() {
        let names = columnNames("sparks")
        if !names.contains("kind") { _ = exec("ALTER TABLE sparks ADD COLUMN kind TEXT NOT NULL DEFAULT 'idea'") }
        if !names.contains("tags") { _ = exec("ALTER TABLE sparks ADD COLUMN tags TEXT NOT NULL DEFAULT ''") }
        if !names.contains("favorite") { _ = exec("ALTER TABLE sparks ADD COLUMN favorite INTEGER NOT NULL DEFAULT 0") }
        if !names.contains("image") { _ = exec("ALTER TABLE sparks ADD COLUMN image BLOB") }
    }

    private func columnNames(_ table: String) -> Set<String> {
        var names = Set<String>()
        scan("PRAGMA table_info(\(table))") { statement in
            names.insert(text(statement, 1))
        }
        return names
    }

    private func write(_ book: QCBook) -> Bool {
        let cleared = [
            "DELETE FROM profile",
            "DELETE FROM categories",
            "DELETE FROM marks",
            "DELETE FROM caps",
            "DELETE FROM accounts",
            "DELETE FROM entries",
            "DELETE FROM removed",
            "DELETE FROM goals",
            "DELETE FROM repeats",
            "DELETE FROM templates",
            "DELETE FROM sparks",
        ]
        guard cleared.allSatisfy({ exec($0) }) else { return false }
        if !run(
            "INSERT INTO profile (id, nickname, gender, locale, currency, monthly, hide_amounts, lock_on_open, daily_reminder, reminder_hour, reminder_minute, sample_cleared, preset_stamp) VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            bind: { statement in
            bindText(statement, 1, book.nickname)
            bindText(statement, 2, book.gender.rawValue)
            bindText(statement, 3, book.locale.rawValue)
            bindText(statement, 4, book.currency.rawValue)
            if let monthly = book.monthlyBudget {
                sqlite3_bind_double(statement, 5, monthly)
            } else {
                sqlite3_bind_null(statement, 5)
            }
            sqlite3_bind_int(statement, 6, book.hideAmounts ? 1 : 0)
            sqlite3_bind_int(statement, 7, book.lockOnOpen ? 1 : 0)
            sqlite3_bind_int(statement, 8, book.dailyReminder ? 1 : 0)
            sqlite3_bind_int(statement, 9, Int32(book.reminderHour))
            sqlite3_bind_int(statement, 10, Int32(book.reminderMinute))
            sqlite3_bind_int(statement, 11, book.sampleCleared ? 1 : 0)
            sqlite3_bind_int(statement, 12, Int32(book.presetStamp))
        }) {
            return false
        }

        for (index, name) in book.categories.enumerated() {
            if !run("INSERT INTO categories (position, name) VALUES (?, ?)", bind: { statement in
                sqlite3_bind_int(statement, 1, Int32(index))
                bindText(statement, 2, name)
            }) {
                return false
            }
        }
        for (name, mark) in book.categoryMarks {
            if !run("INSERT INTO marks (name, mark) VALUES (?, ?)", bind: { statement in
                bindText(statement, 1, name)
                bindText(statement, 2, mark)
            }) {
                return false
            }
        }
        for (name, amount) in book.categoryCaps {
            if !run("INSERT INTO caps (name, amount) VALUES (?, ?)", bind: { statement in
                bindText(statement, 1, name)
                sqlite3_bind_double(statement, 2, amount)
            }) {
                return false
            }
        }
        for (index, account) in book.accounts.enumerated() {
            if !run("INSERT INTO accounts (id, position, name, opening, kind, counts_in_worth, archived, statement_day, due_day) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", bind: { statement in
                bindText(statement, 1, account.id)
                sqlite3_bind_int(statement, 2, Int32(index))
                bindText(statement, 3, account.name)
                sqlite3_bind_double(statement, 4, account.opening)
                bindText(statement, 5, account.kind.rawValue)
                sqlite3_bind_int(statement, 6, account.countsInWorth ? 1 : 0)
                sqlite3_bind_int(statement, 7, account.archived ? 1 : 0)
                sqlite3_bind_int(statement, 8, Int32(account.statementDay))
                sqlite3_bind_int(statement, 9, Int32(account.dueDay))
            }) {
                return false
            }
        }
        // A lista de colunas numa linha não se lê. Fica partida. Não mexer na ordem, corresponde aos índices do bind abaixo
        let entryInsertSQL = """
            INSERT INTO entries (
                id, position, title, amount, direction, category, date,
                account_name, account_id, checked, shared, counts_in_budget,
                claim, refund_of, goal_id, split_group
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
        for (index, entry) in book.entries.enumerated() {
            guard insertEntry(entryInsertSQL, entry, index, removedOn: nil) else { return false }
        }

        let removedInsertSQL = """
            INSERT INTO removed (
                id, position, removed_on, title, amount, direction, category, date,
                account_name, account_id, checked, shared, counts_in_budget,
                claim, refund_of, goal_id, split_group
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
        for (index, item) in book.removed.enumerated() {
            guard insertEntry(removedInsertSQL, item.entry, index, removedOn: item.removedOn) else { return false }
        }
        for (index, goal) in book.goals.enumerated() {
            if !run("INSERT INTO goals (id, position, title, target, saved) VALUES (?, ?, ?, ?, ?)", bind: { statement in
                bindText(statement, 1, goal.id)
                sqlite3_bind_int(statement, 2, Int32(index))
                bindText(statement, 3, goal.title)
                sqlite3_bind_double(statement, 4, goal.target)
                sqlite3_bind_double(statement, 5, goal.saved)
            }) {
                return false
            }
        }
        for (index, plan) in book.repeats.enumerated() {
            if !run("INSERT INTO repeats (id, position, title, amount, direction, category, account_id, shared, counts_in_budget, day, last_month) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", bind: { statement in
                bindText(statement, 1, plan.id)
                sqlite3_bind_int(statement, 2, Int32(index))
                bindText(statement, 3, plan.title)
                sqlite3_bind_double(statement, 4, plan.amount)
                bindText(statement, 5, plan.direction.rawValue)
                bindText(statement, 6, plan.category)
                bindText(statement, 7, plan.accountId)
                sqlite3_bind_int(statement, 8, plan.shared ? 1 : 0)
                sqlite3_bind_int(statement, 9, plan.countsInBudget ? 1 : 0)
                sqlite3_bind_int(statement, 10, Int32(plan.day))
                bindText(statement, 11, plan.lastMonth)
            }) {
                return false
            }
        }
        for (index, template) in book.templates.enumerated() {
            if !run("INSERT INTO templates (id, position, title, amount, direction, category, account_id, shared) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", bind: { statement in
                bindText(statement, 1, template.id)
                sqlite3_bind_int(statement, 2, Int32(index))
                bindText(statement, 3, template.title)
                sqlite3_bind_double(statement, 4, template.amount)
                bindText(statement, 5, template.direction.rawValue)
                bindText(statement, 6, template.category)
                bindText(statement, 7, template.accountId)
                sqlite3_bind_int(statement, 8, template.shared ? 1 : 0)
            }) {
                return false
            }
        }
        for (index, spark) in book.sparks.enumerated() {
            if !run("INSERT INTO sparks (id, position, body, written_on, kind, tags, favorite, image) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", bind: { statement in
                bindText(statement, 1, spark.id)
                sqlite3_bind_int(statement, 2, Int32(index))
                bindText(statement, 3, spark.body)
                bindText(statement, 4, spark.writtenOn)
                bindText(statement, 5, spark.kind.rawValue)
                bindText(statement, 6, spark.tags.joined(separator: "\n"))
                sqlite3_bind_int(statement, 7, spark.favorite ? 1 : 0)
                bindBlob(statement, 8, spark.image)
            }) {
                return false
            }
        }
        return true
    }

    private func insertEntry(_ sql: String, _ entry: QCEntry, _ index: Int, removedOn: String?) -> Bool {
        return run(sql, bind: { statement in
            var column: Int32 = 1
            bindText(statement, column, entry.id)
            column += 1
            sqlite3_bind_int(statement, column, Int32(index))
            column += 1
            if let removedOn {
                bindText(statement, column, removedOn)
                column += 1
            }
            bindText(statement, column, entry.title)
            column += 1
            sqlite3_bind_double(statement, column, entry.amount)
            column += 1
            bindText(statement, column, entry.direction.rawValue)
            column += 1
            bindText(statement, column, entry.category)
            column += 1
            bindText(statement, column, entry.date)
            column += 1
            bindText(statement, column, entry.accountName)
            column += 1
            bindText(statement, column, entry.accountId)
            column += 1
            sqlite3_bind_int(statement, column, entry.checked ? 1 : 0)
            column += 1
            sqlite3_bind_int(statement, column, entry.shared ? 1 : 0)
            column += 1
            sqlite3_bind_int(statement, column, entry.countsInBudget ? 1 : 0)
            column += 1
            bindText(statement, column, entry.claim.rawValue)
            column += 1
            bindText(statement, column, entry.refundOf)
            column += 1
            bindText(statement, column, entry.goalId)
            column += 1
            bindText(statement, column, entry.splitGroup)
        })
    }

    private func accounts() -> [QCAccount] {
        var list: [QCAccount] = []
        scan("SELECT id, name, opening, kind, counts_in_worth, archived, statement_day, due_day FROM accounts ORDER BY position") { statement in
            list.append(QCAccount(
                id: text(statement, 0),
                name: text(statement, 1),
                opening: sqlite3_column_double(statement, 2),
                kind: QCAccountKind.read(text(statement, 3)),
                countsInWorth: flag(statement, 4),
                archived: flag(statement, 5),
                statementDay: int(statement, 6),
                dueDay: int(statement, 7)
            ))
        }
        return list
    }

    private func entries(_ sql: String) -> [QCEntry] {
        var list: [QCEntry] = []
        scan(sql) { statement in
            list.append(readEntry(statement, start: 0))
        }
        return list
    }

    private func removed() -> [QCRemovedEntry] {
        var list: [QCRemovedEntry] = []
        scan("SELECT removed_on, id, title, amount, direction, category, date, account_name, account_id, checked, shared, counts_in_budget, claim, refund_of, goal_id, split_group FROM removed ORDER BY position") { statement in
            list.append(QCRemovedEntry(entry: readEntry(statement, start: 1), removedOn: text(statement, 0)))
        }
        return list
    }

    private func readEntry(_ statement: OpaquePointer, start: Int32) -> QCEntry {
        QCEntry(
            id: text(statement, start),
            title: text(statement, start + 1),
            amount: sqlite3_column_double(statement, start + 2),
            direction: text(statement, start + 3) == QCDirection.income.rawValue ? .income : .out,
            category: text(statement, start + 4),
            date: text(statement, start + 5),
            accountName: text(statement, start + 6),
            accountId: text(statement, start + 7),
            checked: flag(statement, start + 8),
            shared: flag(statement, start + 9),
            countsInBudget: flag(statement, start + 10),
            claim: QCClaimMark.read(text(statement, start + 11)),
            refundOf: text(statement, start + 12),
            goalId: text(statement, start + 13),
            splitGroup: text(statement, start + 14)
        )
    }

    private func goals() -> [QCSavingGoal] {
        var list: [QCSavingGoal] = []
        scan("SELECT id, title, target, saved FROM goals ORDER BY position") { statement in
            list.append(QCSavingGoal(
                id: text(statement, 0),
                title: text(statement, 1),
                target: sqlite3_column_double(statement, 2),
                saved: sqlite3_column_double(statement, 3)
            ))
        }
        return list
    }

    private func repeats() -> [QCRepeatPlan] {
        var list: [QCRepeatPlan] = []
        scan("SELECT id, title, amount, direction, category, account_id, shared, counts_in_budget, day, last_month FROM repeats ORDER BY position") { statement in
            list.append(QCRepeatPlan(
                id: text(statement, 0),
                title: text(statement, 1),
                amount: sqlite3_column_double(statement, 2),
                direction: text(statement, 3) == QCDirection.income.rawValue ? .income : .out,
                category: text(statement, 4),
                accountId: text(statement, 5),
                shared: flag(statement, 6),
                countsInBudget: flag(statement, 7),
                day: int(statement, 8),
                lastMonth: text(statement, 9)
            ))
        }
        return list
    }

    private func templates() -> [QCEntryTemplate] {
        var list: [QCEntryTemplate] = []
        scan("SELECT id, title, amount, direction, category, account_id, shared FROM templates ORDER BY position") { statement in
            list.append(QCEntryTemplate(
                id: text(statement, 0),
                title: text(statement, 1),
                amount: sqlite3_column_double(statement, 2),
                direction: text(statement, 3) == QCDirection.income.rawValue ? .income : .out,
                category: text(statement, 4),
                accountId: text(statement, 5),
                shared: flag(statement, 6)
            ))
        }
        return list
    }

    private func sparks() -> [QCSpark] {
        var list: [QCSpark] = []
        scan("SELECT id, body, written_on, kind, tags, favorite, image FROM sparks ORDER BY position") { statement in
            list.append(QCSpark(
                id: text(statement, 0),
                body: text(statement, 1),
                writtenOn: text(statement, 2),
                kind: QCSparkKind.read(text(statement, 3)),
                tags: text(statement, 4).split(separator: "\n").map(String.init),
                favorite: flag(statement, 5),
                image: blob(statement, 6)
            ))
        }
        return list
    }

    private func strings(_ sql: String) -> [String] {
        var list: [String] = []
        scan(sql) { statement in
            list.append(text(statement, 0))
        }
        return list
    }

    private func pairs(_ sql: String) -> [String: String] {
        var map: [String: String] = [:]
        scan(sql) { statement in
            map[text(statement, 0)] = text(statement, 1)
        }
        return map
    }

    private func amounts(_ sql: String) -> [String: Double] {
        var map: [String: Double] = [:]
        scan(sql) { statement in
            map[text(statement, 0)] = sqlite3_column_double(statement, 1)
        }
        return map
    }

    private func exec(_ sql: String) -> Bool {
        sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK
    }

    private func run(_ sql: String, bind: (OpaquePointer) -> Void) -> Bool {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else { return false }
        defer { sqlite3_finalize(statement) }
        bind(statement)
        return sqlite3_step(statement) == SQLITE_DONE
    }

    private func row(_ sql: String) -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else { return nil }
        guard sqlite3_step(statement) == SQLITE_ROW else {
            sqlite3_finalize(statement)
            return nil
        }
        return statement
    }

    private func scan(_ sql: String, _ read: (OpaquePointer) -> Void) {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else { return }
        defer { sqlite3_finalize(statement) }
        while sqlite3_step(statement) == SQLITE_ROW {
            read(statement)
        }
    }

    private func bindText(_ statement: OpaquePointer, _ index: Int32, _ value: String) {
        sqlite3_bind_text(statement, index, value, -1, transient)
    }

    private func bindBlob(_ statement: OpaquePointer, _ index: Int32, _ data: Data?) {
        guard let data else {
            sqlite3_bind_null(statement, index)
            return
        }
        _ = data.withUnsafeBytes { raw in
            sqlite3_bind_blob(statement, index, raw.baseAddress, Int32(data.count), transient)
        }
    }

    private func blob(_ statement: OpaquePointer, _ index: Int32) -> Data? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else { return nil }
        let count = Int(sqlite3_column_bytes(statement, index))
        guard count > 0, let pointer = sqlite3_column_blob(statement, index) else { return nil }
        return Data(bytes: pointer, count: count)
    }

    private func text(_ statement: OpaquePointer, _ index: Int32) -> String {
        guard let raw = sqlite3_column_text(statement, index) else { return "" }
        return String(cString: raw)
    }

    private func int(_ statement: OpaquePointer, _ index: Int32) -> Int {
        Int(sqlite3_column_int(statement, index))
    }

    private func flag(_ statement: OpaquePointer, _ index: Int32) -> Bool {
        sqlite3_column_int(statement, index) != 0
    }

    private func optionalDouble(_ statement: OpaquePointer, _ index: Int32) -> Double? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else { return nil }
        return sqlite3_column_double(statement, index)
    }
}
