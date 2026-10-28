//
//  Kinds.swift
//  transaction
//
//  Created by Lzl on 2026/10/5.
//

import Foundation

enum BookLocale: String, CaseIterable {
    case zh
    case zhHant = "zh-Hant"
    case en
    case ja
    case ko
    case es
    case pt
    case fr
    case de
    case it

    var title: String {
        switch self {
        case .zh: return "简体中文"
        case .zhHant: return "繁體中文"
        case .en: return "English"
        case .ja: return "日本語"
        case .ko: return "한국어"
        case .es: return "Español"
        case .pt: return "Português"
        case .fr: return "Français"
        case .de: return "Deutsch"
        case .it: return "Italiano"
        }
    }

    static func read(_ raw: Any?) -> BookLocale {
        guard let value = raw as? String, let locale = BookLocale(rawValue: value) else { return .zh }
        return locale
    }
}

enum Gender: String, CaseIterable {
    case female
    case male
    case secret

    static func read(_ raw: Any?) -> Gender {
        guard let value = raw as? String, let gender = Gender(rawValue: value) else { return .secret }
        return gender
    }
}

enum Direction: String {
    case out
    case income = "in"
}

enum AccountKind: String, CaseIterable {
    case bank
    case cash
    case card
    case other

    static let order: [AccountKind] = [.bank, .cash, .card, .other]

    static func read(_ raw: Any?) -> AccountKind {
        guard let value = raw as? String, let kind = AccountKind(rawValue: value) else { return .cash }
        return kind
    }
}

enum HoldingKind: String, CaseIterable {
    case stock
    case etf
    case fund

    static func read(_ raw: Any?) -> HoldingKind {
        guard let value = raw as? String, let kind = HoldingKind(rawValue: value) else { return .stock }
        return kind
    }
}

enum CurrencyCode: String, CaseIterable {
    case USD, EUR, JPY, GBP, HKD, TWD, SGD, AUD, KRW, CAD

    var mark: String {
        switch self {
        case .USD: return "$"
        case .EUR: return "€"
        case .JPY: return "円"
        case .GBP: return "£"
        case .HKD: return "HK$"
        case .TWD: return "NT$"
        case .SGD: return "S$"
        case .AUD: return "A$"
        case .KRW: return "₩"
        case .CAD: return "C$"
        }
    }

    static func read(_ raw: Any?) -> CurrencyCode {
        guard let value = raw as? String, value != "CNY", let code = CurrencyCode(rawValue: value) else { return .USD }
        return code
    }
}

enum LedgerScope: String {
    case mine
    case family
}

enum PeriodMode: String {
    case today
    case month
    case range
}
