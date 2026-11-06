//
//  FormPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/3.
//

import Combine
import SwiftUI

struct FormPage<Content: View>: View {
    var title: String
    var back: String
    var place: String
    var showsBack = true
    @ViewBuilder var content: () -> Content
    @Environment(\.pageBack) private var pageBack

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsBack {
                SubpageHead(title: title, back: back) { pageBack() }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
            } else {
                Text(title)
                    .font(.system(size: 26, weight: .bold))
                    .tracking(-0.4)
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .pageTitleBar()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    content()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
                .immediateScroll(place: place)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
    }
}
