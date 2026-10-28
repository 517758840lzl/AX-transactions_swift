import Foundation

struct PeriodBounds {
    var start: String
    var end: String
}

struct Account: Identifiable, Equatable {
    var id: String
    var name: String
    var opening: Double
    var kind: AccountKind
}

struct Holding: Identifiable, Equatable {
    var id: String
    var kind: HoldingKind
    var code: String
    var name: String
    var qty: Double
    var costTotal: Double
    var price: Double
    var priceAsOf: String
}

struct Entry: Identifiable, Equatable {
    var id: String
    var title: String
    var amount: Double
    var direction: Direction
    var category: String
    var date: String
    var accountName: String
    var accountId: String
    var checked: Bool
    var shared: Bool

    var isOut: Bool { direction == .out }
}

struct EntryTemplate: Identifiable, Equatable {
    var id: String
    var title: String
    var amount: Double
    var direction: Direction
    var category: String
    var accountId: String
    var shared: Bool
}

struct Book {
    var nickname: String
    var gender: Gender
    var locale: BookLocale
    var currency: CurrencyCode
    var monthlyBudget: Double?
    var categoryCaps: [String: Double]
    var templates: [EntryTemplate]
    var categories: [String]
    var accounts: [Account]
    var holdings: [Holding]
    var entries: [Entry]
    var sampleCleared: Bool

    var mark: String { currency.mark }

    static func empty() -> Book {
        Book(
            nickname: "",
            gender: .secret,
            locale: .zh,
            currency: .USD,
            monthlyBudget: nil,
            categoryCaps: [:],
            templates: [],
            categories: LedgerCopy.resolve(.zh).starterCategories,
            accounts: [],
            holdings: [],
            entries: [],
            sampleCleared: false
        )
    }
}

enum LedgerID {
    static func make() -> String {
        String(Int(Date().timeIntervalSince1970 * 1_000_000))
    }
}
