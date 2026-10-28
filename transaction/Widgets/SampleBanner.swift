//
//  SampleBanner.swift
//  transaction
//
//  Created by Lzl on 2026/10/22.
//

import Combine
import SwiftUI

struct SampleBanner: View {
    var title: String
    var actionTitle: String
    var action: () -> Void

    var body: some View {
        HStack {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ink)
            Spacer()
            Button(actionTitle, action: action)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.ink)
        }
        .padding(14)
        .background(Palette.wash, in: RoundedRectangle(cornerRadius: 14))
    }
}
