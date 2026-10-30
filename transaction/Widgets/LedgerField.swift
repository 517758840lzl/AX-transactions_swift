//
//  LedgerField.swift
//  transaction
//
//  Created by Lzl on 2026/10/8.
//

import Combine
import SwiftUI
import UIKit

struct LedgerField: View {
    var text: Binding<String>
    var placeholder: String
    var decimal = false

    var body: some View {
        Group {
            if decimal {
                DecimalPadField(text: text, placeholder: placeholder)
            } else {
                TextField(placeholder, text: text)
                    .textInputAutocapitalization(.sentences)
            }
        }
        .font(.system(size: 16))
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.line, lineWidth: 1))
    }
}

/// Money entry. The system text field keeps pasted letters unless the change is refused here.
private struct DecimalPadField: UIViewRepresentable {
    var text: Binding<String>
    var placeholder: String

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.keyboardType = .decimalPad
        field.font = .systemFont(ofSize: 16)
        field.textColor = UIColor(red: 11 / 255, green: 5 / 255, blue: 29 / 255, alpha: 1)
        field.tintColor = field.textColor
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.placeholder = placeholder
        field.text = text.wrappedValue
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.text = text
        if field.text != text.wrappedValue {
            field.text = text.wrappedValue
        }
        field.placeholder = placeholder
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: text)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textField(_ field: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let current = field.text ?? ""
            guard let span = Range(range, in: current) else { return false }
            let next = LedgerMoney.typing(current.replacingCharacters(in: span, with: string))
            text.wrappedValue = next
            if field.text != next { field.text = next }
            return false
        }
    }
}
