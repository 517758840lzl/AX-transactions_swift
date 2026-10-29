//
//  LedgerMoney.swift
//  transaction
//
//  Created by Lzl on 2026/10/6.
//

import Foundation

enum LedgerMoney {
    static func cents(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    /// Fixed decimals. 2 for money, 0 for whole shares.
    static func fixed(_ value: Double, fraction: Int) -> String {
        String(format: "%.\(fraction)f", value)
    }

    static func signedPercent(_ value: Double) -> String {
        let sign = value > 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }

    static func body(_ value: Double) -> String {
        let scaled = cents(abs(value))
        let text = fixed(scaled, fraction: 2)
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        let digits = String(parts[0])
        var grouped = ""
        for (offset, character) in digits.reversed().enumerated() {
            if offset > 0, offset % 3 == 0 { grouped.append(",") }
            grouped.append(character)
        }
        let fraction = parts.count > 1 ? String(parts[1]) : "00"
        return String(grouped.reversed()) + "." + fraction
    }

    /// Digits and one dot. The rest is dropped.
    static func typing(_ raw: String) -> String {
        var kept = ""
        var dotted = false
        for character in raw {
            if character >= "0" && character <= "9" {
                kept.append(character)
            } else if character == ".", !dotted {
                dotted = true
                kept.append(character)
            }
        }
        return kept
    }

    /// A plain amount, or a little sum like 12+8.
    static func solve(_ raw: String) -> Double? {
        let text = raw
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "＋", with: "+")
            .replacingOccurrences(of: "－", with: "-")
            .replacingOccurrences(of: "−", with: "-")
        guard !text.isEmpty else { return nil }
        var total = 0.0
        var number = ""
        var sign = 1.0
        func flush() -> Bool {
            if number.isEmpty { return false }
            guard let value = Double(number) else { return false }
            total += sign * value
            number = ""
            return true
        }
        for character in text {
            if character == "+" || character == "-" {
                guard flush() else { return nil }
                sign = character == "-" ? -1 : 1
            } else {
                number.append(character)
            }
        }
        guard flush() else { return nil }
        return total
    }

    static func text(_ value: Double, mark: String, signed: Bool = false) -> String {
        let sign: String
        if signed, value > 0 {
            sign = "+"
        } else if value < 0 {
            sign = "−"
        } else {
            sign = ""
        }
        return sign + mark + body(value)
    }
}
