import Foundation

struct YearColumn: Identifiable {
    var month: Int
    var spend: Double
    var income: Double
    var id: Int { month }
}

struct PeriodBounds {
    var start: String
    var end: String
}

struct Account: Identifiable, Equatable {
    var id: String
    var name: String
    var opening: Double
    var kind: AccountKind
    var countsInWorth: Bool
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
    var countsInBudget: Bool
    var claim: ClaimMark

    var isOut: Bool { direction == .out }
}

enum ClaimMark: String {
    case none
    case waiting
    case done

    static func read(_ raw: Any?) -> ClaimMark {
        guard let value = raw as? String, let mark = ClaimMark(rawValue: value) else { return .none }
        return mark
    }
}

struct SavingGoal: Identifiable, Equatable {
    var id: String
    var title: String
    var target: Double
    var saved: Double
}

struct RepeatPlan: Identifiable, Equatable {
    var id: String
    var title: String
    var amount: Double
    var direction: Direction
    var category: String
    var accountId: String
    var shared: Bool
    var countsInBudget: Bool
    var day: Int
    var lastMonth: String
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
    var repeats: [RepeatPlan]
    var goals: [SavingGoal]
    var hideAmounts: Bool
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
            repeats: [],
            goals: [],
            hideAmounts: false,
            sampleCleared: false
        )
    }
}

enum LedgerID {
    static func make() -> String {
        String(Int(Date().timeIntervalSince1970 * 1_000_000))
    }
}
