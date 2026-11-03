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
        guard let data = try? JSONSerialization.data(withJSONObject: map),
              let text = String(data: data, encoding: .utf8),
              let book = BookDocument.decode(text) else {
            return Book.empty()
        }
        return book
    }

    static func accounts() -> [Account] { seed().accounts }
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

    static func displayTitle(id: String, title: String, locale: BookLocale) -> String {
        let bare = stripTag(title)
        let known = names[id] ?? [:]
        let base = known.values.contains(bare) ? (known[locale.rawValue] ?? known["en"] ?? bare) : bare
        let suffix = " (\(tag(locale)))"
        return base.hasSuffix(suffix) ? base : base + suffix
    }

    private static let names: [String: [String: String]] = [
        "sample-lunch": [
            "zh": "午餐", "zh-Hant": "午餐", "en": "Lunch", "ja": "ランチ", "ko": "점심",
            "es": "Comida", "pt": "Almoço", "fr": "Déjeuner", "de": "Mittagessen", "it": "Pranzo",
        ],
        "sample-coffee": [
            "zh": "咖啡", "zh-Hant": "咖啡", "en": "Coffee", "ja": "コーヒー", "ko": "커피",
            "es": "Café", "pt": "Café", "fr": "Café", "de": "Kaffee", "it": "Caffè",
        ],
        "sample-metro": [
            "zh": "地铁", "zh-Hant": "地鐵", "en": "Metro", "ja": "地下鉄", "ko": "지하철",
            "es": "Metro", "pt": "Metro", "fr": "Métro", "de": "U-Bahn", "it": "Metro",
        ],
    ]

    private static func tag(_ locale: BookLocale) -> String {
        switch locale {
        case .zh, .zhHant: return "示例"
        case .en: return "Sample"
        case .ja: return "例"
        case .ko: return "예시"
        case .es: return "ejemplo"
        case .pt: return "exemplo"
        case .fr: return "exemple"
        case .de: return "Beispiel"
        case .it: return "esempio"
        }
    }

    static func bareTitle(_ title: String) -> String {
        stripTag(title)
    }

    private static func stripTag(_ title: String) -> String {
        let tags = ["示例", "Sample", "例", "예시", "ejemplo", "exemplo", "exemple", "Beispiel", "esempio"]
        for tag in tags {
            let suffix = " (\(tag))"
            if title.hasSuffix(suffix) { return String(title.dropLast(suffix.count)) }
        }
        return title
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
