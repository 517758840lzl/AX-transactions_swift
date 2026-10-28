import Foundation

enum BookDocument {
    static func encode(_ book: Book) -> String {
        let object = jsonObject(book)
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
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
                ] as [String: Any]
            },
            "holdings": book.holdings.map { holding in
                [
                    "id": holding.id,
                    "kind": holding.kind.rawValue,
                    "code": holding.code,
                    "name": holding.name,
                    "qty": holding.qty,
                    "costTotal": holding.costTotal,
                    "price": holding.price,
                    "priceAsOf": holding.priceAsOf,
                ] as [String: Any]
            },
            "entries": book.entries.map { entry in
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
                ] as [String: Any]
            },
            "nickname": book.nickname,
            "gender": book.gender.rawValue,
            "locale": book.locale.rawValue,
            "currency": book.currency.rawValue,
        ]
    }

    static func book(from map: [String: Any]) -> Book {
        let sampleCleared = map["sampleCleared"] as? Bool ?? false
        var book = Book.empty()
        book.sampleCleared = sampleCleared
        book.nickname = map["nickname"] as? String ?? ""
        book.gender = Gender.read(map["gender"])
        book.locale = map["locale"] as? String == "en" ? .en : .zh
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
        book.holdings = holdings(map["holdings"], sampleCleared: sampleCleared)
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
                kind: AccountKind.read(map["kind"])
            )
        }
    }

    private static func holdings(_ raw: Any?, sampleCleared: Bool) -> [Holding] {
        guard let list = raw as? [Any] else { return sampleCleared ? [] : SampleBook.holdings() }
        return list.compactMap { item in
            guard let map = item as? [String: Any] else { return nil }
            return holding(map)
        }
    }

    private static func holding(_ map: [String: Any]) -> Holding {
        Holding(
            id: "\(map["id"] ?? "")",
            kind: HoldingKind.read(map["kind"]),
            code: "\(map["code"] ?? "")",
            name: "\(map["name"] ?? "")",
            qty: money(map["qty"]) ?? 0,
            costTotal: money(map["costTotal"]) ?? 0,
            price: money(map["price"]) ?? 0,
            priceAsOf: "\(map["priceAsOf"] ?? "")"
        )
    }

    private static func entries(_ raw: Any?, sampleCleared: Bool) -> [Entry] {
        guard let list = raw as? [Any] else { return sampleCleared ? [] : SampleBook.entries() }
        return list.compactMap { item in
            guard let map = item as? [String: Any] else { return nil }
            return Entry(
                id: "\(map["id"] ?? "")",
                title: "\(map["title"] ?? "")",
                amount: money(map["amount"]) ?? 0,
                direction: map["direction"] as? String == "in" ? .income : .out,
                category: "\(map["category"] ?? "")",
                date: "\(map["date"] ?? "")",
                accountName: "\(map["accountName"] ?? "")",
                accountId: "\(map["accountId"] ?? "")",
                checked: map["checked"] as? Bool ?? false,
                shared: map["shared"] as? Bool ?? false
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
