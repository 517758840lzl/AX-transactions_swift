//
//  SampleBook.swift
//  transaction
//
//  Created by Lzl on 2026/10/12.
//

import Foundation

enum SampleBook {
    static func seed(now: Date = Date()) -> Book {
        guard var map = document() else { return Book.empty() }
        let names = accountNames(map["accounts"])
        if var rows = map["entries"] as? [[String: Any]] {
            for index in rows.indices {
                rows[index]["date"] = date(for: rows[index], now: now)
                if let accountId = rows[index]["accountId"] as? String {
                    rows[index]["accountName"] = names[accountId] ?? ""
                }
            }
            map["entries"] = rows
        }
        if var rows = map["holdings"] as? [[String: Any]] {
            for index in rows.indices where (rows[index]["priceAsOf"] as? String)?.isEmpty != false {
                rows[index]["priceAsOf"] = LedgerDay.today(now)
            }
            map["holdings"] = rows
        }
        guard let data = try? JSONSerialization.data(withJSONObject: map),
              let text = String(data: data, encoding: .utf8),
              let book = BookDocument.decode(text) else {
            return Book.empty()
        }
        return book
    }

    static func accounts() -> [Account] { seed().accounts }
    static func holdings(now: Date = Date()) -> [Holding] { seed(now: now).holdings }
    static func entries(now: Date = Date()) -> [Entry] { seed(now: now).entries }

    private static func document() -> [String: Any]? {
        guard let url = Bundle.main.url(forResource: "sample-book", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let map = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return map
    }

    private static func accountNames(_ raw: Any?) -> [String: String] {
        guard let rows = raw as? [[String: Any]] else { return [:] }
        var names: [String: String] = [:]
        for row in rows {
            names["\(row["id"] ?? "")"] = "\(row["name"] ?? "")"
        }
        return names
    }

    private static func date(for row: [String: Any], now: Date) -> String {
        if let ago = row["ago"] as? Int {
            let date = Calendar.current.date(byAdding: .day, value: -ago, to: now) ?? now
            return LedgerDay.iso(date)
        }
        let offset = row["monthOffset"] as? Int ?? 0
        let day = row["monthDay"] as? Int ?? 1
        return LedgerDay.dateInMonth(offset: offset, day: day, now: now)
    }
}
