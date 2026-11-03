//
//  CategoryGrid.swift
//  transaction
//
//  Created by Lzl on 2026/11/3.
//

import SwiftUI

struct CategoryGrid: View {
    var names: [String]
    var marks: [String: String]
    var selected: String = ""
    var editing: Bool = false
    var canRemove: Bool = false
    var rows: Int? = nil
    var addTitle: String = ""
    var onRemove: ((String) -> Void)? = nil
    var onSelect: ((String) -> Void)? = nil
    var onAdd: (() -> Void)? = nil

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    private var shown: [String] {
        let cap = rows.map { $0 * 4 - (onAdd == nil ? 0 : 1) } ?? names.count
        guard names.count > cap else { return names }
        var next = Array(names.prefix(cap))
        if !selected.isEmpty, !next.contains(selected), cap > 0 {
            next[cap - 1] = selected
        }
        return next
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(shown, id: \.self) { name in
                cell(name)
            }
            if let onAdd {
                Button(action: onAdd) {
                    VStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                            .frame(width: 52, height: 52)
                            .background(Palette.wash, in: Circle())
                            .overlay(Circle().stroke(Palette.line, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                        Text(addTitle)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func cell(_ name: String) -> some View {
        let style = CategoryMarks.style(name: name, marks: marks)
        let on = name == selected && !selected.isEmpty
        ZStack(alignment: .topTrailing) {
            if let onSelect {
                Button {
                    onSelect(name)
                } label: {
                    face(style: style, on: on, name: name)
                }
                .buttonStyle(.plain)
            } else {
                face(style: style, on: on, name: name)
            }
            if editing, canRemove, let onRemove {
                Button {
                    onRemove(name)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 18, height: 18)
                        .background(Palette.ink, in: Circle())
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -2)
            }
        }
    }

    private func face(style: CategoryStyle, on: Bool, name: String) -> some View {
        VStack(spacing: 6) {
            CategoryBadge(style: style, selected: on, side: 52)
            Text(name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
        }
    }
}

struct CategoryMarkPicker: View {
    var selected: String
    var onSelect: (String) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(CategoryMarks.pickerKeys, id: \.self) { key in
                let style = CategoryMarks.style(key: key)
                Button {
                    onSelect(key)
                } label: {
                    CategoryBadge(style: style, selected: key == selected, side: 52)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(key)
            }
        }
    }
}

struct CategoryFormView: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
    var slot: String
    @Environment(\.pageBack) private var pageBack
    @State private var name = ""
    @State private var markKey = "tag"

    var body: some View {
        let copy = store.copy
        let pending = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let taken = !pending.isEmpty && store.book.categories.contains(pending)
        FormPage(title: copy.newCategory, back: copy.back) {
            CategoryMarkPicker(selected: markKey) { markKey = $0 }
            FieldLabel(text: copy.name)
            LedgerField(text: $name, placeholder: copy.newCategory)
            PillButton(title: copy.add, enabled: !pending.isEmpty && !taken) {
                store.addCategory(pending, mark: markKey)
                screen.categoryPickSlot = slot
                screen.categoryPickName = pending
                pageBack()
            }
        }
    }
}

struct CategoryBadge: View {
    var style: CategoryStyle
    var selected: Bool
    var side: CGFloat

    var body: some View {
        Image(systemName: style.symbol)
            .font(.system(size: side * 0.38, weight: .semibold))
            .foregroundStyle(style.tint)
            .frame(width: side, height: side)
            .background(style.tint.opacity(selected ? 0.22 : 0.14), in: Circle())
            .overlay(Circle().stroke(selected ? style.tint : Color.clear, lineWidth: 2.5))
    }
}
