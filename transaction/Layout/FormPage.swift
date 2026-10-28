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
    @ViewBuilder var content: () -> Content
    @Environment(\.pageBack) private var pageBack

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SubpageHead(title: title, back: back) { pageBack() }
                content()
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 32)
            .immediateScroll()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
        .keyboardBar(keyboardDone)
    }

    @Environment(\.keyboardDone) private var keyboardDone
}
