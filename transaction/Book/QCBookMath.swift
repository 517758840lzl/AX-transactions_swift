//
//  QCBookMath.swift
//  transaction
//
//  Created by Lzl on 2026/10/6.
//

import Foundation

struct QCWindowSnapshot {
    var amounts: [Double]
    var prior: Double
    var netWorth: Double
    var cashBalance: Double

    var delta: Double { netWorth - prior }
}

struct QCCategoryPart: Identifiable {
    var id: String { name }
    var name: String
    var amount: Double
    var colorIndex: Int
    var budgetCap: Double?
}

struct QCRecurringItem: Identifiable {
    var id: String { "\(title)|\(amount)" }
    var title: String
    var amount: Double
    var times: Int
}

enum QCSliceColors {
    static let values = ["E85D75", "F4A261", "E9C46A", "C47B84", "8D6E63", "E8A0BF", "B5838D", "6B705C"]
}

enum QCBookMath {
    static let windowDays = [7, 30]
}
