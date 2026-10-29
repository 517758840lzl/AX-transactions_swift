//
//  BookDocument.swift
//  transaction
//
//  Created by Lzl on 2026/10/7.
//

import Foundation

enum BookDocument {
    static func encode(_ book: Book, pretty: Bool = false) -> String {
        let object = jsonObject(book)
        var options: JSONSerialization.WritingOptions = [.sortedKeys]
        if pretty { options.insert(.prettyPrinted) }
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: options),
              let text = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return text
    }

    static func decode(_ raw: String) -> Book? {
        guard let data = raw.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data),
              let map = parsed as? [String: Any] else {
            return nil
        }
        return book(from: map)
    }

    static func jsonObject(_ book: Book) -> [String: Any] {
        [
            "sampleCleared": book.sampleCleared,
            "hideAmounts": book.hideAmounts,
            "lockOnOpen": book.lockOnOpen,
            "monthly": book.monthlyBudget as Any? ?? NSNull(),
            "categoryCaps": book.categoryCaps,
            "categories": book.categories,
            "templates": book.templates.map { template in
                [
                    "id": template.id,
                    "title": template.title,
                    "amount": template.amount,
                    "direction": template.direction.rawValue,
                    "category": template.category,
                    "accountId": template.accountId,
                    "shared": template.shared,
                ] as [String: Any]
            },
            "accounts": book.accounts.map { account in
                [
                    "id": account.id,
                    "name": account.name,
                    "opening": account.opening,
                    "kind": account.kind.rawValue,
                    "countsInWorth": account.countsInWorth,
                    "archived": account.archived,
                    "statementDay": account.statementDay,
                    "dueDay": account.dueDay,
                ] as [String: Any]
            },
            "entries": book.entries.map { entryObject($0) },
            "goals": book.goals.map { goal in
                [
                    "id": goal.id,
                    "title": goal.title,
                    "target": goal.target,
                    "saved": goal.saved,
                ] as [String: Any]
            },
            "repeats": book.repeats.map { plan in
                [
                    "id": plan.id,
                    "title": plan.title,
                    "amount": plan.amount,
                    "direction": plan.direction.rawValue,
                    "category": plan.category,
                    "accountId": plan.accountId,
                    "shared": plan.shared,
                    "countsInBudget": plan.countsInBudget,
                    "day": plan.day,
                    "lastMonth": plan.lastMonth,
                ] as [String: Any]
            },
            "nickname": book.nickname,
            "gender": book.gender.rawValue,
            "locale": book.locale.rawValue,
            "currency": book.currency.rawValue,
            "removed": book.removed.map { item in
                [
                    "removedOn": item.removedOn,
                    "entry": entryObject(item.entry),
                ] as [String: Any]
            },
        ]
    }

    private static func entryObject(_ entry: Entry) -> [String: Any] {
        [
            "id": entry.id,
            "title": entry.title,
            "amount": entry.amount,
            "direction": entry.direction.rawValue,
            "category": entry.category,
            "date": entry.date,
            "accountName": entry.accountName,
            "accountId": entry.accountId,
            "checked": entry.checked,
            "shared": entry.shared,
            "countsInBudget": entry.countsInBudget,
            "claim": entry.claim.rawValue,
            "refundOf": entry.refundOf,
            "goalId": entry.goalId,
            "splitGroup": entry.splitGroup,
        ]
    }

    static func book(from map: [String: Any]) -> Book {
        let sampleCleared = map["sampleCleared"] as? Bool ?? false
        var book = Book.empty()
        book.sampleCleared = sampleCleared
        book.hideAmounts = map["hideAmounts"] as? Bool ?? false
        book.lockOnOpen = map["lockOnOpen"] as? Bool ?? false
        book.removed = removed(map["removed"])
        book.goals = goals(map["goals"])
        book.repeats = repeats(map["repeats"])
        book.nickname = map["nickname"] as? String ?? ""
        book.gender = Gender.read(map["gender"])
        book.locale = BookLocale.read(map["locale"])
        book.currency = CurrencyCode.read(map["currency"])
        book.monthlyBudget = money(map["monthly"]) ?? money(map["budget"])
        if let caps = map["categoryCaps"] as? [String: Any] {
            book.categoryCaps = moneyMap(caps)
        } else if let caps = map["categoryBudgets"] as? [String: Any] {
            book.categoryCaps = moneyMap(caps)
        }
        if let names = map["categories"] as? [Any], !names.isEmpty {
            book.categories = names.map { "\($0)" }
        }
        book.templates = templates(map["templates"])
        book.accounts = accounts(map["accounts"], sampleCleared: sampleCleared)
        book.entries = entries(map["entries"], sampleCleared: sampleCleared)
        return book
    }

    private static func accounts(_ raw: Any?, sampleCleared: Bool) -> [Account] {
        guard let list = raw as? [Any] else { return sampleCleared ? [] : SampleBook.accounts() }
        return list.compactMap { item in
            guard let map = item as? [String: Any] else { return nil }
            return Account(
                id: "\(map["id"] ?? "")",
                name: "\(map["name"] ?? "")",
                opening: money(map["opening"]) ?? 0,
                kind: AccountKind.read(map["kind"]),
                countsInWorth: map["countsInWorth"] as? Bool ?? true,
                archived: map["archived"] as? Bool ?? false,
                statementDay: day(map["statementDay"]),
                dueDay: day(map["dueDay"])
            )
        }
    }

    private static func entries(_ raw: Any?, sampleCleared: Bool) -> [Entry] {
        guard let list = raw as? [Any] else { return sampleCleared ? [] : SampleBook.entries() }
        return list.compactMap { item in
            guard let map = item as? [String: Any] else { return nil }
            return readEntry(map)
        }
    }

    private static func day(_ raw: Any?) -> Int {
        let value = raw as? Int ?? Int(money(raw) ?? 0)
        guard value >= 1 else { return 0 }
        return min(value, 28)
    }

    private static func readEntry(_ map: [String: Any]) -> Entry {
        Entry(
            id: "\(map["id"] ?? "")",
            title: "\(map["title"] ?? "")",
            amount: money(map["amount"]) ?? 0,
            direction: map["direction"] as? String == "in" ? .income : .out,
            category: "\(map["category"] ?? "")",
            date: "\(map["date"] ?? "")",
            accountName: "\(map["accountName"] ?? "")",
            accountId: "\(map["accountId"] ?? "")",
            checked: map["checked"] as? Bool ?? false,
            shared: map["shared"] as? Bool ?? false,
            countsInBudget: map["countsInBudget"] as? Bool ?? true,
            claim: ClaimMark.read(map["claim"]),
            refundOf: "\(map["refundOf"] ?? "")",
            goalId: "\(map["goalId"] ?? "")",
            splitGroup: "\(map["splitGroup"] ?? "")"
        )
    }

    private static func removed(_ raw: Any?) -> [RemovedEntry] {
        guard let list = raw as? [Any] else { return [] }
        return list.compactMap { item in
            guard let map = item as? [String: Any], let entryMap = map["entry"] as? [String: Any] else { return nil }
            return RemovedEntry(entry: readEntry(entryMap), removedOn: "\(map["removedOn"] ?? "")")
        }
    }

    private static func goals(_ raw: Any?) -> [SavingGoal] {
        guard let list = raw as? [Any] else { return [] }
        return list.compactMap { item in
            guard let map = item as? [String: Any] else { return nil }
            return SavingGoal(
                id: "\(map["id"] ?? "")",
                title: "\(map["title"] ?? "")",
                target: money(map["target"]) ?? 0,
                saved: money(map["saved"]) ?? 0
            )
        }
    }

    private static func repeats(_ raw: Any?) -> [RepeatPlan] {
        guard let list = raw as? [Any] else { return [] }
        return list.compactMap { item in
            guard let map = item as? [String: Any] else { return nil }
            let day = map["day"] as? Int ?? 1
            return RepeatPlan(
                id: "\(map["id"] ?? "")",
                title: "\(map["title"] ?? "")",
                amount: money(map["amount"]) ?? 0,
                direction: map["direction"] as? String == "in" ? .income : .out,
                category: "\(map["category"] ?? "")",
                accountId: "\(map["accountId"] ?? "")",
                shared: map["shared"] as? Bool ?? false,
                countsInBudget: map["countsInBudget"] as? Bool ?? true,
                day: min(max(day, 1), 28),
                lastMonth: "\(map["lastMonth"] ?? "")"
            )
        }
    }

    private static func templates(_ raw: Any?) -> [EntryTemplate] {
        guard let list = raw as? [Any] else { return [] }
        return list.compactMap { item in
            guard let map = item as? [String: Any] else { return nil }
            return EntryTemplate(
                id: "\(map["id"] ?? "")",
                title: "\(map["title"] ?? "")",
                amount: money(map["amount"]) ?? 0,
                direction: map["direction"] as? String == "in" ? .income : .out,
                category: "\(map["category"] ?? "")",
                accountId: "\(map["accountId"] ?? "")",
                shared: map["shared"] as? Bool ?? false
            )
        }
    }

    private static func moneyMap(_ raw: [String: Any]) -> [String: Double] {
        var caps: [String: Double] = [:]
        for (key, value) in raw {
            if let amount = money(value) { caps[key] = amount }
        }
        return caps
    }

    private static func money(_ raw: Any?) -> Double? {
        if raw is NSNull { return nil }
        if let number = raw as? NSNumber { return number.doubleValue }
        return nil
    }
}
