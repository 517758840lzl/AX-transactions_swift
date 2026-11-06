//
//  QCAvatarMark.swift
//  transaction
//
//  Created by Lzl on 2026/10/23.
//

import SwiftUI

enum QCLedgerAvatar {
    static func mark(for gender: QCGender) -> String {
        switch gender {
        case .female: return "👩"
        case .male: return "👨"
        case .secret: return "🧑"
        }
    }
}

struct QCAvatarMark: View {
    var gender: QCGender
    var size: CGFloat

    var body: some View {
        Text(QCLedgerAvatar.mark(for: gender))
            .font(.system(size: size * 0.58))
            .frame(width: size, height: size)
            .background(QCPalette.neutral, in: Circle())
    }
}
