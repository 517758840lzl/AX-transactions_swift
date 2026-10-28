import Foundation

struct WindowSnapshot {
    var amounts: [Double]
    var prior: Double
    var netWorth: Double
    var cashBalance: Double
    var holdingsTotal: Double

    var delta: Double { netWorth - prior }
}

struct CategoryPart: Identifiable {
    var id: String { name }
    var name: String
    var amount: Double
    var colorIndex: Int
    var budgetCap: Double?
}

struct RecurringItem: Identifiable {
    var id: String { "\(title)|\(amount)" }
    var title: String
    var amount: Double
    var times: Int
}

enum SliceColors {
    static let values = ["E85D75", "F4A261", "E9C46A", "C47B84", "8D6E63", "E8A0BF", "B5838D", "6B705C"]
}

enum BookMath {
    static let windowDays = [7, 30]
}
