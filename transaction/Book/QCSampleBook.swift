//
//  QCSampleBook.swift
//  transaction
//
//  Created by Lzl on 2026/10/12.
//

enum QCSampleBook {
    static func displayTitle(id: String, title: String, locale: QCBookLocale) -> String {
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

    private static func tag(_ locale: QCBookLocale) -> String {
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

    static func starterTitles(_ locale: QCBookLocale) -> [String] {
        starters.compactMap { row in
            let title = row[locale.rawValue] ?? row["en"] ?? ""
            return title.isEmpty ? nil : title
        }
    }

    private static let starters: [[String: String]] = [
        ["zh": "午餐", "zh-Hant": "午餐", "en": "Lunch", "ja": "ランチ", "ko": "점심", "es": "Comida", "pt": "Almoço", "fr": "Déjeuner", "de": "Mittagessen", "it": "Pranzo"],
        ["zh": "咖啡", "zh-Hant": "咖啡", "en": "Coffee", "ja": "コーヒー", "ko": "커피", "es": "Café", "pt": "Café", "fr": "Café", "de": "Kaffee", "it": "Caffè"],
        ["zh": "地铁", "zh-Hant": "地鐵", "en": "Metro", "ja": "地下鉄", "ko": "지하철", "es": "Metro", "pt": "Metro", "fr": "Métro", "de": "U-Bahn", "it": "Metro"],
        ["zh": "早饭", "zh-Hant": "早飯", "en": "Breakfast", "ja": "朝食", "ko": "아침", "es": "Desayuno", "pt": "Manhã", "fr": "Petit-déj", "de": "Frühstück", "it": "Colazione"],
        ["zh": "晚饭", "zh-Hant": "晚飯", "en": "Dinner", "ja": "夕食", "ko": "저녁", "es": "Cena", "pt": "Jantar", "fr": "Dîner", "de": "Abendessen", "it": "Cena"],
        ["zh": "买菜", "zh-Hant": "買菜", "en": "Groceries", "ja": "食料品", "ko": "장보기", "es": "Mercado", "pt": "Mercado", "fr": "Courses", "de": "Einkauf", "it": "Spesa"],
        ["zh": "零食", "zh-Hant": "零食", "en": "Snacks", "ja": "おやつ", "ko": "간식", "es": "Snack", "pt": "Lanche", "fr": "Goûter", "de": "Snack", "it": "Snack"],
        ["zh": "打车", "zh-Hant": "叫車", "en": "Taxi", "ja": "タクシー", "ko": "택시", "es": "Taxi", "pt": "Táxi", "fr": "Taxi", "de": "Taxi", "it": "Taxi"],
        ["zh": "购物", "zh-Hant": "購物", "en": "Shopping", "ja": "買い物", "ko": "쇼핑", "es": "Compras", "pt": "Compras", "fr": "Magasin", "de": "Shopping", "it": "Shopping"],
        ["zh": "房租", "zh-Hant": "房租", "en": "Rent", "ja": "家賃", "ko": "월세", "es": "Alquiler", "pt": "Aluguel", "fr": "Loyer", "de": "Miete", "it": "Affitto"],
        ["zh": "话费", "zh-Hant": "話費", "en": "Phone", "ja": "携帯代", "ko": "통신비", "es": "Móvil", "pt": "Celular", "fr": "Forfait", "de": "Handy", "it": "Telefono"],
        ["zh": "工资", "zh-Hant": "薪水", "en": "Salary", "ja": "給料", "ko": "월급", "es": "Sueldo", "pt": "Salário", "fr": "Salaire", "de": "Gehalt", "it": "Stipendio"],
    ]

    private static func stripTag(_ title: String) -> String {
        let tags = ["示例", "Sample", "例", "예시", "ejemplo", "exemplo", "exemple", "Beispiel", "esempio"]
        for tag in tags {
            let suffix = " (\(tag))"
            if title.hasSuffix(suffix) { return String(title.dropLast(suffix.count)) }
        }
        return title
    }
}
