//
//  QCRecords.swift
//  transaction
//
//  Created by Lzl on 2026/10/5.
//

import Foundation

struct QCYearColumn: Identifiable {
    var month: Int
    var spend: Double
    var income: Double
    var id: Int { month }
}

struct QCPeriodBounds {
    var start: String
    var end: String
}

struct QCAccount: Identifiable, Equatable {
    var id: String
    var name: String
    var opening: Double
    var kind: QCAccountKind
    var countsInWorth: Bool
    var archived: Bool = false
    /// 1...28. Zero means no statement day yet.
    var statementDay: Int = 0
    var dueDay: Int = 0
}

struct QCEntry: Identifiable, Equatable {
    var id: String
    var title: String
    var amount: Double
    var direction: QCDirection
    var category: String
    var date: String
    var accountName: String
    var accountId: String
    var checked: Bool
    var shared: Bool
    var countsInBudget: Bool
    var claim: QCClaimMark
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

struct QCRemovedEntry: Equatable, Identifiable {
    var entry: QCEntry
    var removedOn: String
    var id: String { entry.id }
}

struct QCCardCycle {
    var start: String
    var end: String
    var due: String
    var spent: Double
}

enum QCClaimMark: String {
    case none
    case waiting
    case done

    static func read(_ raw: Any?) -> QCClaimMark {
        guard let value = raw as? String, let mark = QCClaimMark(rawValue: value) else { return .none }
        return mark
    }
}

struct QCSavingGoal: Identifiable, Equatable {
    var id: String
    var title: String
    var target: Double
    var saved: Double
}

struct QCRepeatPlan: Identifiable, Equatable {
    var id: String
    var title: String
    var amount: Double
    var direction: QCDirection
    var category: String
    var accountId: String
    var shared: Bool
    var countsInBudget: Bool
    var day: Int
    var lastMonth: String
}

enum QCSparkKind: String, CaseIterable {
    case idea
    case diary
    case thought
    case summary

    static func read(_ raw: String) -> QCSparkKind {
        QCSparkKind(rawValue: raw) ?? .idea
    }
}

struct QCSpark: Identifiable, Equatable {
    var id: String
    var body: String
    /// Day the thought belongs to, `yyyy-MM-dd`.
    var writtenOn: String
    var kind: QCSparkKind = .idea
    var tags: [String] = []
    var favorite: Bool = false
    var image: Data?
}

struct QCEntryTemplate: Identifiable, Equatable {
    var id: String
    var title: String
    var amount: Double
    var direction: QCDirection
    var category: String
    var accountId: String
    var shared: Bool
}

struct QCBook {
    var nickname: String
    var gender: QCGender
    var locale: QCBookLocale
    var currency: QCCurrencyCode
    var monthlyBudget: Double?
    var categoryCaps: [String: Double]
    var templates: [QCEntryTemplate]
    var categories: [String]
    var accounts: [QCAccount]
    var entries: [QCEntry]
    var repeats: [QCRepeatPlan]
    var goals: [QCSavingGoal]
    var sparks: [QCSpark]
    var hideAmounts: Bool
    var lockOnOpen: Bool
    var dailyReminder: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var removed: [QCRemovedEntry]
    var sampleCleared: Bool
    var categoryMarks: [String: String]
    var presetStamp: Int

    var mark: String { currency.mark }

    static func empty() -> QCBook {
        QCBook(
            nickname: "",
            gender: .secret,
            locale: .en,
            currency: .USD,
            monthlyBudget: nil,
            categoryCaps: [:],
            templates: [],
            categories: QCLedgerCopy.resolve(.en).starterCategories,
            accounts: [],
            entries: [],
            repeats: [],
            goals: [],
            sparks: [],
            hideAmounts: false,
            lockOnOpen: false,
            dailyReminder: false,
            reminderHour: 21,
            reminderMinute: 30,
            removed: [],
            sampleCleared: false,
            categoryMarks: [:],
            presetStamp: 2
        )
    }
}

enum QCSparkTags {
    static func parse(_ raw: String) -> [String] {
        var seen = Set<String>()
        var tags: [String] = []
        let pieces = raw.split { character in
            character == " " || character == "," || character == "，" || character == "\n" || character == "#"
        }
        for piece in pieces {
            let tag = String(piece).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !tag.isEmpty, tag.count <= 20, seen.insert(tag).inserted else { continue }
            tags.append(tag)
            if tags.count == 8 { break }
        }
        return tags
    }
}

enum QCLedgerID {
    static func make() -> String {
        String(Int(Date().timeIntervalSince1970 * 1_000_000))
    }
}
