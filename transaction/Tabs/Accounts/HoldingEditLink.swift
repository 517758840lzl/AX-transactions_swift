//
//  HoldingEditLink.swift
//  transaction
//
//  Created by Lzl on 2026/10/22.
//

import Combine
import SwiftUI

struct HoldingEditLink: View {
    var holdingID: String
    var title: String
    @EnvironmentObject private var screen: LedgerScreen

    var body: some View {
        Button {
            screen.open(.holdingForm(id: holdingID))
        } label: {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(Palette.ink)
                .background(Palette.pink, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
