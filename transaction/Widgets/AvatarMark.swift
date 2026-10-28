//
//  AvatarMark.swift
//  transaction
//
//  Created by Lzl on 2026/10/23.
//

import SwiftUI

enum LedgerAvatar {
    static func mark(for gender: Gender) -> String {
        switch gender {
        case .female: return "👩"
        case .male: return "👨"
        case .secret: return "🧑"
        }
    }
}

struct AvatarMark: View {
    var gender: Gender
    var size: CGFloat

    var body: some View {
        Text(LedgerAvatar.mark(for: gender))
            .font(.system(size: size * 0.58))
            .frame(width: size, height: size)
            .background(Palette.neutral, in: Circle())
    }
}
