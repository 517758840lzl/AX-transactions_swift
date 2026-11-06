//
//  QCLedgerField.swift
//  transaction
//
//  Created by Lzl on 2026/10/8.
//

import SwiftUI
import UIKit

struct QCLedgerField: View {
    var text: Binding<String>
    var placeholder: String
    var decimal = false
    var marked = false

    var body: some View {
        Group {
            if decimal {
                QCDecimalPadField(text: text, placeholder: placeholder)
            } else {
                QCPlainField(text: text, placeholder: placeholder)
            }
        }
        .font(.system(size: 16))
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(marked ? QCPalette.down : QCPalette.line, lineWidth: 1))
    }
}

// The system field keeps pasted letters. Drop them here.
private struct QCDecimalPadField: UIViewRepresentable {
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

    func makeCoordinator() -> QCCoordinator {
        QCCoordinator(text: text)
    }

    final class QCCoordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textField(_ field: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let current = field.text ?? ""
            guard let span = Range(range, in: current) else { return false }
            let next = QCLedgerMoney.typing(current.replacingCharacters(in: span, with: string))
            text.wrappedValue = next
            if field.text != next { field.text = next }
            return false
        }
    }
}

// Return closes the keyboard.
private struct QCPlainField: UIViewRepresentable {
    var text: Binding<String>
    var placeholder: String

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.font = .systemFont(ofSize: 16)
        field.textColor = UIColor(red: 11 / 255, green: 5 / 255, blue: 29 / 255, alpha: 1)
        field.tintColor = field.textColor
        field.autocorrectionType = .default
        field.autocapitalizationType = .sentences
        field.placeholder = placeholder
        field.text = text.wrappedValue
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.addTarget(context.coordinator, action: #selector(QCCoordinator.changed(_:)), for: .editingChanged)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.text = text
        if field.text != text.wrappedValue {
            field.text = text.wrappedValue
        }
        field.placeholder = placeholder
    }

    func makeCoordinator() -> QCCoordinator {
        QCCoordinator(text: text)
    }

    final class QCCoordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        @objc func changed(_ field: UITextField) {
            let next = field.text ?? ""
            if text.wrappedValue != next { text.wrappedValue = next }
        }

        func textFieldShouldReturn(_ field: UITextField) -> Bool {
            field.resignFirstResponder()
            return true
        }
    }
}
