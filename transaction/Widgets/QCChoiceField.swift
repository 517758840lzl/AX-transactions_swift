//
//  QCChoiceField.swift
//  transaction
//
//  Created by Lzl on 2026/10/21.
//

import SwiftUI
import UIKit

struct QCChoiceOption: Identifiable {
    var id: String
    var title: String
}

// The list opens just above the field. Nothing dims behind it.
struct QCChoiceField: View {
    var label: String
    var title: String
    var options: [QCChoiceOption]
    var selectedID: String
    var marked = false
    var onSelect: (String) -> Void
    @State private var open = false
    @State private var placeAbove = true
    @State private var cardHeight: CGFloat = 0

    private var listHeight: CGFloat {
        let rows = CGFloat(options.count) * 44
        let rules = CGFloat(max(options.count - 1, 0))
        return cardHeight > 0 ? cardHeight : rows + rules
    }

    var body: some View {
        Button {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            open.toggle()
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundStyle(QCPalette.ink)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(QCPalette.ink)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .frame(maxWidth: .infinity)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(marked ? QCPalette.down : QCPalette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: QCChoiceFrameKey.self, value: geo.frame(in: .global))
            }
        )
        .onPreferenceChange(QCChoiceFrameKey.self) { frame in
            placeAbove = frame.minY > listHeight + 88
        }
        .overlay(alignment: .top) {
            if open {
                list
                    .frame(maxWidth: .infinity)
                    .offset(y: placeAbove ? -(listHeight + 8) : 56)
                    .background {
                        Color.clear
                            .frame(width: 2000, height: 2400)
                            .contentShape(Rectangle())
                            .onTapGesture { open = false }
                    }
            }
        }
        .zIndex(open ? 2 : 0)
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                let selected = option.id == selectedID
                Button {
                    onSelect(option.id)
                    open = false
                } label: {
                    HStack(spacing: 8) {
                        Text(option.title)
                            .font(.system(size: 15))
                            .foregroundStyle(QCPalette.ink)
                        Spacer(minLength: 8)
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(QCPalette.ink)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if index < options.count - 1 {
                    Rectangle()
                        .fill(QCPalette.line)
                        .frame(height: 1)
                        .padding(.leading, 16)
                }
            }
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: QCPalette.ink.opacity(0.16), radius: 20, y: 16)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: QCChoiceHeightKey.self, value: geo.size.height)
            }
        )
        .onPreferenceChange(QCChoiceHeightKey.self) { cardHeight = $0 }
    }
}

private struct QCChoiceFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

private struct QCChoiceHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
