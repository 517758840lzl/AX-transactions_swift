//
//  PrivacyPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/26.
//

import Combine
import SwiftUI

struct PrivacyView: View {
    var title: String
    @Environment(\.pageBack) private var pageBack

    var body: some View {
        VStack(spacing: 0) {
            SubpageHead(title: title, back: "Back") { pageBack() }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            if let url = Bundle.main.url(forResource: "privacy", withExtension: "html") {
                PrivacyWeb(url: url)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
    }
}
