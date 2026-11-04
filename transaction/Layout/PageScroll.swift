//
//  PageScroll.swift
//  transaction
//
//  Created by Lzl on 2026/10/3.
//

import Combine
import SwiftUI

struct PageScroll<Content: View>: View {
    var place: String
    var bottom: CGFloat = 28
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            // Plain stack. A lazy one keeps remeasuring these few cards while the finger is down.
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, bottom)
            .immediateScroll(place: place)
        }
        .background(Palette.stage)
    }
}
