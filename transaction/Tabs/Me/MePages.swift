import Combine
import SwiftUI

struct CategoryManageView: View {
    @ObservedObject var store: BookStore
    @State private var editing = false
    @State private var newCategory = ""

    var body: some View {
        let copy = store.copy
        let pending = newCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        FormPage(title: copy.categories, back: copy.back) {
            HStack {
                Spacer()
                Button(editing ? copy.done : copy.edit) { editing.toggle() }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Palette.ink)
            }
            FlowChips(names: store.book.categories, editing: editing, canRemove: store.book.categories.count > 1) { name in
                store.removeCategory(name)
            }
            HStack(spacing: 8) {
                LedgerField(text: $newCategory, placeholder: copy.newCategory)
                Button(copy.add) {
                    store.addCategory(pending)
                    newCategory = ""
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 18)
                .frame(minHeight: 48)
                .background(Palette.pink, in: Capsule())
                .opacity(pending.isEmpty ? 0.45 : 1)
                .disabled(pending.isEmpty)
            }
        }
    }
}

struct LanguagePickView: View {
    @ObservedObject var store: BookStore

    var body: some View {
        let copy = store.copy
        FormPage(title: copy.language, back: copy.back) {
            pickCard(BookLocale.allCases.map { locale in
                (locale.title, store.book.locale == locale, { store.setLocale(locale) })
            })
        }
    }
}

struct CurrencyPickView: View {
    @ObservedObject var store: BookStore

    var body: some View {
        let copy = store.copy
        FormPage(title: copy.currency, back: copy.back) {
            pickCard(CurrencyCode.allCases.map { code in
                ("\(code.rawValue)  \(code.mark)", store.book.currency == code, { store.setCurrency(code) })
            })
        }
    }
}

private func pickCard(_ rows: [(String, Bool, () -> Void)]) -> some View {
    VStack(spacing: 0) {
        ForEach(rows.indices, id: \.self) { index in
            Button(action: rows[index].2) {
                HStack(spacing: 12) {
                    Text(rows[index].0)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Spacer(minLength: 8)
                    if rows[index].1 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Palette.ink)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if index < rows.count - 1 {
                Rectangle().fill(Palette.line).frame(height: 1)
            }
        }
    }
    .padding(.horizontal, 16)
    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Palette.line, lineWidth: 1))
}
