//
//  QCFormPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/3.
//

import SwiftUI

struct QCFormPage<Content: View>: View {
    var title: String
    var back: String
    var place: String
    var showsBack = true
    var side: CGFloat = 18
    @ViewBuilder var content: () -> Content
    @Environment(\.pageBack) private var pageBack

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsBack {
                QCSubpageHead(title: title, back: back) { pageBack() }
                    .padding(.horizontal, side)
                    .padding(.top, 8)
                    .padding(.bottom, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
            } else {
                Text(title)
                    .font(.system(size: 26, weight: .bold))
                    .tracking(-0.4)
                    .foregroundStyle(QCPalette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .pageTitleBar()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    content()
                }
                .padding(.horizontal, side)
                .padding(.bottom, 32)
                .immediateScroll(place: place)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
    }
}
