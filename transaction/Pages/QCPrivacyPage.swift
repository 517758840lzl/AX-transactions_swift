//
//  QCPrivacyPage.swift
//  transaction
//
//  Created by Lzl on 2026/10/26.
//

import SwiftUI

struct QCPrivacyView: View {
    var title: String
    @Environment(\.pageBack) private var pageBack

    var body: some View {
        VStack(spacing: 0) {
            QCSubpageHead(title: title, back: "Back") { pageBack() }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            if let url = Bundle.main.url(forResource: "privacy", withExtension: "html") {
                QCPrivacyWeb(url: url)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
    }
}
