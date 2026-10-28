//
//  SubpageHead.swift
//  transaction
//
//  Created by Lzl on 2026/10/8.
//

import Combine
import SwiftUI

struct SubpageHead: View {
    var title: String
    var back: String
    var action: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: action) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel(back)
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Palette.ink)
            Spacer()
        }
    }
}
