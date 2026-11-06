//
//  QCSampleBanner.swift
//  transaction
//
//  Created by Lzl on 2026/10/22.
//

import SwiftUI

struct QCSampleBanner: View {
    var title: String
    var actionTitle: String
    var action: () -> Void

    var body: some View {
        HStack {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(QCPalette.ink)
            Spacer()
            Button(actionTitle, action: action)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(QCPalette.ink)
        }
        .padding(14)
        .background(QCPalette.wash, in: RoundedRectangle(cornerRadius: 14))
    }
}
