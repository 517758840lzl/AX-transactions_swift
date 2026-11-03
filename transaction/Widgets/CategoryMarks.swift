//
//  CategoryMarks.swift
//  transaction
//
//  Created by Lzl on 2026/11/3.
//

import SwiftUI

struct CategoryStyle {
    var key: String
    var symbol: String
    var red: Double
    var green: Double
    var blue: Double

    var tint: Color { Color(red: red, green: green, blue: blue) }
}

enum CategoryMarks {
    static let choices: [CategoryStyle] = [
        CategoryStyle(key: "dining", symbol: "fork.knife", red: 0.90, green: 0.42, blue: 0.28),
        CategoryStyle(key: "transit", symbol: "bus.fill", red: 0.18, green: 0.52, blue: 0.70),
        CategoryStyle(key: "shopping", symbol: "bag.fill", red: 0.55, green: 0.38, blue: 0.20),
        CategoryStyle(key: "daily", symbol: "cart.fill", red: 0.32, green: 0.46, blue: 0.72),
        CategoryStyle(key: "housing", symbol: "house.fill", red: 0.46, green: 0.38, blue: 0.72),
        CategoryStyle(key: "snacks", symbol: "cup.and.saucer.fill", red: 0.82, green: 0.46, blue: 0.22),
        CategoryStyle(key: "clothes", symbol: "tshirt.fill", red: 0.70, green: 0.36, blue: 0.52),
        CategoryStyle(key: "entertainment", symbol: "face.smiling.fill", red: 0.78, green: 0.34, blue: 0.48),
        CategoryStyle(key: "social", symbol: "person.2.fill", red: 0.68, green: 0.30, blue: 0.46),
        CategoryStyle(key: "pets", symbol: "pawprint.fill", red: 0.52, green: 0.40, blue: 0.26),
        CategoryStyle(key: "kids", symbol: "person.fill", red: 0.84, green: 0.42, blue: 0.52),
        CategoryStyle(key: "sports", symbol: "figure.walk", red: 0.18, green: 0.55, blue: 0.40),
        CategoryStyle(key: "medical", symbol: "cross.case.fill", red: 0.74, green: 0.28, blue: 0.32),
        CategoryStyle(key: "phone", symbol: "iphone", red: 0.26, green: 0.40, blue: 0.72),
        CategoryStyle(key: "education", symbol: "book.fill", red: 0.32, green: 0.38, blue: 0.68),
        CategoryStyle(key: "subscriptions", symbol: "repeat.circle.fill", red: 0.46, green: 0.34, blue: 0.66),
        CategoryStyle(key: "income", symbol: "arrow.down.circle.fill", red: 0.18, green: 0.56, blue: 0.38),
        CategoryStyle(key: "travel", symbol: "airplane", red: 0.22, green: 0.48, blue: 0.62),
        CategoryStyle(key: "beauty", symbol: "sparkles", red: 0.76, green: 0.38, blue: 0.56),
        CategoryStyle(key: "transfer", symbol: "arrow.left.arrow.right", red: 0.40, green: 0.40, blue: 0.48),
        CategoryStyle(key: "tag", symbol: "tag.fill", red: 0.45, green: 0.40, blue: 0.48),
    ]

    static let pickerKeys = choices.map(\.key).filter { $0 != "transfer" }

    static func style(name: String, marks: [String: String]) -> CategoryStyle {
        let key = marks[name] ?? known[name] ?? "tag"
        return choices.first { $0.key == key } ?? choices[choices.count - 1]
    }

    static func style(key: String) -> CategoryStyle {
        choices.first { $0.key == key } ?? choices[choices.count - 1]
    }

    /// Adds the newer presets once. A list the person already edited keeps its own names.
    static func adopt(_ book: inout Book) -> Bool {
        guard book.presetStamp < 2 else { return false }
        let current = Set(book.categories)
        if let matched = previous.first(where: { Set($0) == current }) {
            book.categories = LedgerCopy.resolve(locale(of: matched[0])).starterCategories
        } else {
            for name in extras(book.locale) where !book.categories.contains(name) {
                book.categories.append(name)
            }
        }
        book.presetStamp = 2
        return true
    }

    private static func extras(_ locale: BookLocale) -> [String] {
        switch locale {
        case .zh: return ["购物", "零食", "服饰", "社交", "宠物", "养娃", "运动", "医疗", "通讯", "教育", "旅行", "美容"]
        case .zhHant: return ["購物", "零食", "服飾", "社交", "寵物", "養娃", "運動", "醫療", "通訊", "教育", "旅行", "美容"]
        case .en: return ["Shopping", "Snacks", "Clothes", "Social", "Pets", "Kids", "Sports", "Medical", "Phone", "Education", "Travel", "Beauty"]
        case .ja: return ["買い物", "軽食", "衣服", "交際", "ペット", "子育て", "運動", "医療", "通信", "教育", "旅行", "美容"]
        case .ko: return ["쇼핑", "간식", "의류", "모임", "반려동물", "육아", "운동", "의료", "통신", "교육", "여행", "미용"]
        case .es: return ["Compras", "Snacks", "Ropa", "Social", "Mascotas", "Niños", "Deporte", "Salud", "Teléfono", "Estudios", "Viajes", "Belleza"]
        case .pt: return ["Compras", "Lanches", "Roupas", "Social", "Pets", "Filhos", "Esporte", "Saúde", "Telefone", "Estudos", "Viagens", "Beleza"]
        case .fr: return ["Courses", "Snacks", "Vêtements", "Social", "Animaux", "Enfants", "Sport", "Santé", "Téléphone", "Études", "Voyages", "Beauté"]
        case .de: return ["Einkauf", "Snacks", "Kleidung", "Sozial", "Tiere", "Kinder", "Sport", "Gesundheit", "Telefon", "Lernen", "Reisen", "Pflege"]
        case .it: return ["Spesa", "Snack", "Vestiti", "Social", "Animali", "Bambini", "Sport", "Salute", "Telefono", "Studio", "Viaggi", "Bellezza"]
        }
    }

    private static func locale(of first: String) -> BookLocale {
        switch first {
        case "餐饮": return .zh
        case "餐飲": return .zhHant
        case "食費": return .ja
        case "식비": return .ko
        case "Comida": return .es
        case "Alimentação": return .pt
        case "Repas": return .fr
        case "Essen": return .de
        case "Pasti": return .it
        default: return .en
        }
    }

    private static let previous: [[String]] = [
        ["餐饮", "交通", "日用", "居住", "收入", "订阅", "娱乐"],
        ["餐飲", "交通", "日用", "居住", "收入", "訂閱", "娛樂"],
        ["Dining", "Transit", "Daily", "Housing", "Income", "Subscriptions", "Entertainment"],
        ["食費", "交通", "日用品", "住居", "収入", "サブスク", "娯楽"],
        ["식비", "교통", "생활", "주거", "수입", "구독", "여가"],
        ["Comida", "Transporte", "Diario", "Vivienda", "Ingresos", "Suscripciones", "Ocio"],
        ["Alimentação", "Transporte", "Dia a dia", "Moradia", "Receitas", "Assinaturas", "Lazer"],
        ["Repas", "Transports", "Quotidien", "Logement", "Revenus", "Abonnements", "Loisirs"],
        ["Essen", "Verkehr", "Alltag", "Wohnen", "Einnahmen", "Abos", "Freizeit"],
        ["Pasti", "Trasporti", "Quotidiano", "Casa", "Entrate", "Abbonamenti", "Svago"],
    ]

    private static let known: [String: String] = [
        "餐饮": "dining", "餐飲": "dining", "Dining": "dining", "食費": "dining", "식비": "dining",
        "Comida": "dining", "Alimentação": "dining", "Repas": "dining", "Essen": "dining", "Pasti": "dining",
        "交通": "transit", "Transit": "transit", "Transporte": "transit", "Transports": "transit", "Verkehr": "transit", "Trasporti": "transit",
        "교통": "transit",
        "购物": "shopping", "購物": "shopping", "Shopping": "shopping", "買い物": "shopping", "쇼핑": "shopping",
        "Compras": "shopping", "Courses": "shopping", "Einkauf": "shopping", "Spesa": "shopping",
        "日用": "daily", "Daily": "daily", "日用品": "daily", "생활": "daily", "Diario": "daily", "Dia a dia": "daily",
        "Quotidien": "daily", "Alltag": "daily", "Quotidiano": "daily",
        "居住": "housing", "Housing": "housing", "住居": "housing", "주거": "housing", "Vivienda": "housing",
        "Moradia": "housing", "Logement": "housing", "Wohnen": "housing", "Casa": "housing",
        "零食": "snacks", "Snacks": "snacks", "軽食": "snacks", "간식": "snacks", "Lanches": "snacks", "Snack": "snacks",
        "服饰": "clothes", "服飾": "clothes", "Clothes": "clothes", "衣服": "clothes", "의류": "clothes",
        "Ropa": "clothes", "Roupas": "clothes", "Vêtements": "clothes", "Kleidung": "clothes", "Vestiti": "clothes",
        "娱乐": "entertainment", "娛樂": "entertainment", "Entertainment": "entertainment", "娯楽": "entertainment", "여가": "entertainment",
        "Ocio": "entertainment", "Lazer": "entertainment", "Loisirs": "entertainment", "Freizeit": "entertainment", "Svago": "entertainment",
        "社交": "social", "Social": "social", "交際": "social", "모임": "social", "Sozial": "social",
        "宠物": "pets", "寵物": "pets", "Pets": "pets", "ペット": "pets", "반려동물": "pets",
        "Mascotas": "pets", "Animaux": "pets", "Tiere": "pets", "Animali": "pets",
        "养娃": "kids", "養娃": "kids", "Kids": "kids", "子育て": "kids", "육아": "kids",
        "Niños": "kids", "Filhos": "kids", "Enfants": "kids", "Kinder": "kids", "Bambini": "kids",
        "运动": "sports", "運動": "sports", "Sports": "sports", "운동": "sports", "Deporte": "sports",
        "Esporte": "sports", "Sport": "sports",
        "医疗": "medical", "醫療": "medical", "Medical": "medical", "医療": "medical", "의료": "medical",
        "Salud": "medical", "Saúde": "medical", "Santé": "medical", "Gesundheit": "medical", "Salute": "medical",
        "通讯": "phone", "通訊": "phone", "Phone": "phone", "通信": "phone", "통신": "phone",
        "Teléfono": "phone", "Telefone": "phone", "Téléphone": "phone", "Telefon": "phone", "Telefono": "phone",
        "教育": "education", "Education": "education", "교육": "education", "Estudios": "education", "Estudos": "education",
        "Études": "education", "Lernen": "education", "Studio": "education",
        "订阅": "subscriptions", "訂閱": "subscriptions", "Subscriptions": "subscriptions", "サブスク": "subscriptions", "구독": "subscriptions",
        "Suscripciones": "subscriptions", "Assinaturas": "subscriptions", "Abonnements": "subscriptions", "Abos": "subscriptions", "Abbonamenti": "subscriptions",
        "收入": "income", "収入": "income", "Income": "income", "수입": "income", "Ingresos": "income",
        "Receitas": "income", "Revenus": "income", "Einnahmen": "income", "Entrate": "income",
        "旅行": "travel", "Travel": "travel", "여행": "travel", "Viajes": "travel",
        "Viagens": "travel", "Voyages": "travel", "Reisen": "travel", "Viaggi": "travel",
        "美容": "beauty", "Beauty": "beauty", "미용": "beauty", "Belleza": "beauty",
        "Beleza": "beauty", "Beauté": "beauty", "Pflege": "beauty",
        "转账": "transfer", "轉帳": "transfer", "振替": "transfer", "이체": "transfer", "Transfer": "transfer",
        "Transferencia": "transfer", "Transferência": "transfer", "Virement": "transfer", "Umbuchung": "transfer", "Trasferimento": "transfer",
    ]
}
