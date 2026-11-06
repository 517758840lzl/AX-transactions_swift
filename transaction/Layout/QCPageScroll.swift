//
//  QCPageScroll.swift
//  transaction
//
//  Created by Lzl on 2026/10/3.
//

import SwiftUI

struct QCPageScroll<Content: View>: View {
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
            .padding(.bottom, bottom)
            .immediateScroll(place: place)
        }
        .background(QCPalette.stage)
    }
}

extension View {
    /// Keeps a page title above the scrolling content, aligned to the left.
    func pageTitleBar(fill: Color = QCPalette.stage) -> some View {
        padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill)
    }
}
