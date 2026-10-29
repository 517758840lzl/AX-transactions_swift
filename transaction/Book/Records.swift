//
//  Records.swift
//  transaction
//
//  Created by Lzl on 2026/10/5.
//

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
    var archived: Bool = false
    /// 1...28. Zero means no statement day yet.
    var statementDay: Int = 0
    var dueDay: Int = 0
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
    /// Set on the money that came back. Blank on the original spend.
    var refundOf: String = ""
    /// Goal this spend counts toward.
    var goalId: String = ""
    /// Ties the two halves of one purchase.
    var splitGroup: String = ""

    var isOut: Bool { direction == .out }
    /// Both sides of a transfer between your own accounts. Household spend and income skip these.
    var isTransfer: Bool { id.hasPrefix("transfer-") }
}

struct RemovedEntry: Equatable, Identifiable {
    var entry: Entry
    var removedOn: String
    var id: String { entry.id }
}

struct CardCycle {
    var start: String
    var end: String
    var due: String
    var spent: Double
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
    var entries: [Entry]
    var repeats: [RepeatPlan]
    var goals: [SavingGoal]
    var hideAmounts: Bool
    var lockOnOpen: Bool
    var removed: [RemovedEntry]
    var sampleCleared: Bool

    var mark: String { currency.mark }

    static func empty() -> Book {
        Book(
            nickname: "",
            gender: .secret,
            locale: .en,
            currency: .USD,
            monthlyBudget: nil,
            categoryCaps: [:],
            templates: [],
            categories: LedgerCopy.resolve(.en).starterCategories,
            accounts: [],
            entries: [],
            repeats: [],
            goals: [],
            hideAmounts: false,
            lockOnOpen: false,
            removed: [],
            sampleCleared: false
        )
    }
}

enum LedgerID {
    static func make() -> String {
        String(Int(Date().timeIntervalSince1970 * 1_000_000))
    }
}
