//
//  LedgerField.swift
//  transaction
//
//  Created by Lzl on 2026/10/8.
//

import Combine
import SwiftUI

struct LedgerField: View {
    var text: Binding<String>
    var placeholder: String
    var decimal = false

    var body: some View {
        TextField(placeholder, text: text)
            .keyboardType(decimal ? .decimalPad : .default)
            .textInputAutocapitalization(decimal ? .never : .sentences)
            .disableAutocorrection(decimal)
            .font(.system(size: 16))
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.line, lineWidth: 1))
    }
}
