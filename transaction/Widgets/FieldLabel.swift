//
//  FieldLabel.swift
//  transaction
//
//  Created by Lzl on 2026/10/8.
//

import Combine
import SwiftUI

struct FieldLabel: View {
    var text: String
    var body: some View {
        Text(text).font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.ink)
    }
}
