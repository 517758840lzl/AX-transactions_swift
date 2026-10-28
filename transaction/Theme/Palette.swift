//
//  Palette.swift
//  transaction
//
//  Created by Lzl on 2026/10/1.
//

import Combine
import SwiftUI

enum Palette {
    static let pink = Color(red: 1, green: 179 / 255, blue: 199 / 255)
    static let wash = Color(red: 1, green: 242 / 255, blue: 245 / 255)
    static let ink = Color(red: 11 / 255, green: 5 / 255, blue: 29 / 255)
    static let muted = Color(red: 110 / 255, green: 104 / 255, blue: 120 / 255)
    static let faint = Color(red: 155 / 255, green: 150 / 255, blue: 163 / 255)
    static let line = Color(red: 240 / 255, green: 221 / 255, blue: 227 / 255)
    static let neutral = Color(red: 246 / 255, green: 244 / 255, blue: 248 / 255)
    static let stage = Color(red: 243 / 255, green: 240 / 255, blue: 244 / 255)
    static let up = Color(red: 47 / 255, green: 158 / 255, blue: 98 / 255)
    static let down = Color(red: 232 / 255, green: 93 / 255, blue: 117 / 255)
    static let review = Color(red: 169 / 255, green: 112 / 255, blue: 14 / 255)
    static let heroUp = Color(red: 142 / 255, green: 228 / 255, blue: 176 / 255)
    static let onDark = Color.white.opacity(0.62)
    static let onDarkSoft = Color.white.opacity(0.88)

    static func slice(_ index: Int) -> Color {
        let hex = SliceColors.values[index % SliceColors.values.count]
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
