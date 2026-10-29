//
//  PageScroll.swift
//  transaction
//
//  Created by Lzl on 2026/10/3.
//

import Combine
import SwiftUI

struct PageScroll<Content: View>: View {
    var bottom: CGFloat = 28
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            // A plain stack. The four tabs are a few cards, and a lazy stack remeasures them while the finger moves.
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, bottom)
            .immediateScroll()
        }
        .background(Palette.stage)
        .keyboardBar(keyboardDone)
    }

    @Environment(\.keyboardDone) private var keyboardDone
}
