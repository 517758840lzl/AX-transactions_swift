import Combine
import SwiftUI

struct MeView: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
    @State private var editingCategories = false
    @State private var newCategory = ""

    var body: some View {
        let copy = store.copy
        let streak = BookMath.streakDays(store.book.entries)
        let logged = BookMath.loggedToday(store.book.entries)
        let name = store.book.nickname.isEmpty ? copy.unsetName : store.book.nickname
        PageScroll(bottom: 16) {
            Text(copy.me).font(.system(size: 26, weight: .bold)).tracking(-0.4).foregroundStyle(Palette.ink)
            PanelCard(card: true) {
                Button { screen.open(.profile) } label: {
                    HStack(spacing: 14) {
                        AvatarMark(gender: store.book.gender, size: 56)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(name)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Palette.ink)
                                    .lineLimit(1)
                                if !store.book.nickname.isEmpty {
                                    Image(systemName: genderSymbol(store.book.gender))
                                        .font(.system(size: 16))
                                        .foregroundStyle(Palette.muted)
                                        .accessibilityLabel(copy.genderName(store.book.gender))
                                }
                            }
                            if store.book.nickname.isEmpty {
                                Text(copy.profileHint).font(.system(size: 13)).foregroundStyle(Palette.muted)
                            }
                            Text("\(copy.streakDays) \(streak) · \(logged ? copy.streakToday : copy.streakNone)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Palette.muted)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            PanelCard(card: true) {
                settingsRow(copy.monthlyBudget, trailing: budgetText(copy), value: true) { screen.open(.budget) }
                divider
                settingsRow(copy.exportBook, trailing: "›") { screen.open(.data) }
                divider
                settingsRow(copy.importData, trailing: "›") { screen.open(.importBook) }
                divider
                settingsRow(copy.privacy, trailing: "›") { screen.open(.privacy) }
                divider
                labeled(copy.language) {
                    ChoiceRow(labels: [copy.localeZh, copy.localeEn], index: store.book.locale == .zh ? 0 : 1) { index in
                        store.setLocale(index == 0 ? .zh : .en)
                    }
                }
                divider
                labeled(copy.currency) {
                    ChoiceRow(labels: CurrencyCode.allCases.map(\.rawValue), index: CurrencyCode.allCases.firstIndex(of: store.book.currency) ?? 0, columns: 5) { index in
                        store.setCurrency(CurrencyCode.allCases[index])
                    }
                }
            }

            PanelCard(title: copy.categories, titleSize: 15, card: true, trailing: {
                Button(editingCategories ? copy.done : copy.edit) { editingCategories.toggle() }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Palette.ink)
            }) {
                FlowChips(names: store.book.categories, editing: editingCategories, canRemove: store.book.categories.count > 1) { name in
                    store.removeCategory(name)
                }
                let pending = newCategory.trimmingCharacters(in: .whitespacesAndNewlines)
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
                .padding(.top, 12)
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(Palette.line.opacity(0.95)).frame(height: 1).padding(.vertical, 4)
    }

    private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.muted)
            content()
        }
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    private func budgetText(_ copy: LedgerCopy) -> String {
        if let budget = store.book.monthlyBudget, budget > 0 {
            return LedgerMoney.text(budget, mark: store.book.mark)
        }
        return copy.budgetUnset
    }

    private func settingsRow(_ title: String, trailing: String, value: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: 8)
                Text(trailing)
                    .font(.system(size: value ? 14 : 20, weight: value ? .bold : .regular))
                    .foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func genderSymbol(_ gender: Gender) -> String {
        switch gender {
        case .female: return "figure.stand.dress"
        case .male: return "figure.stand"
        case .secret: return "lock"
        }
    }
}
