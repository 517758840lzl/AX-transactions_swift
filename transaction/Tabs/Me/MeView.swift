import Combine
import SwiftUI
import UniformTypeIdentifiers

struct MeView: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
    @State private var pickingFile = false
    @State private var pendingImport = ""
    @State private var confirmImport = false
    @State private var confirmClear = false

    var body: some View {
        let copy = store.copy
        let streak = BookMath.streakDays(store.book.entries)
        let logged = BookMath.loggedToday(store.book.entries)
        let name = store.book.nickname.isEmpty ? copy.unsetName : store.book.nickname
        let languageName = store.book.locale.title
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

            PanelCard(title: copy.meLedger, titleSize: 13, card: true) {
                settingsRow(copy.yearReport, opens: true) { screen.open(.yearReport) }
                divider
                settingsRow(copy.monthlyBudget, trailing: budgetText(copy), opens: true) { screen.open(.budget) }
                divider
                settingsRow(copy.savingGoals, trailing: store.book.goals.isEmpty ? "" : "\(store.book.goals.count)", opens: true) { screen.open(.savingGoals) }
                divider
                settingsRow(copy.categories, trailing: "\(store.book.categories.count)", opens: true) { screen.open(.categories) }
            }

            PanelCard(title: copy.meDisplay, titleSize: 13, card: true) {
                settingsRow(copy.hideAmounts, trailing: store.book.hideAmounts ? copy.hideAmountsOn : copy.hideAmountsOff) {
                    store.setHideAmounts(!store.book.hideAmounts)
                }
                divider
                settingsRow(copy.lockOnOpen, trailing: store.book.lockOnOpen ? copy.lockOnWord : copy.lockOffWord) {
                    store.setLockOnOpen(!store.book.lockOnOpen)
                }
                divider
                settingsRow(copy.language, trailing: languageName, opens: true) { screen.open(.language) }
                divider
                settingsRow(copy.currency, trailing: "\(store.book.currency.rawValue) \(store.book.mark)", opens: true) { screen.open(.currency) }
            }

            PanelCard(title: copy.meData, titleSize: 13, card: true) {
                settingsRow(copy.exportBook, opens: true) { ShareSheet.present(store.exportText()) }
                divider
                settingsRow(copy.importData, opens: true) { pickingFile = true }
                divider
                settingsRow(copy.removedTitle, trailing: store.book.removed.isEmpty ? "" : "\(store.book.removed.count)", opens: true) {
                    screen.open(.removed)
                }
                divider
                settingsRow(copy.clearBook, opens: true, destructive: true) { confirmClear = true }
            }

            PanelCard(card: true) {
                settingsRow(copy.privacy, opens: true) { screen.open(.privacy) }
            }
        }
        .fileImporter(isPresented: $pickingFile, allowedContentTypes: [.json, .plainText]) { result in
            guard case .success(let url) = result, url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            let text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            guard BookDocument.decode(text) != nil else {
                store.flash(store.copy.importInvalid)
                return
            }
            pendingImport = text
            confirmImport = true
        }
        .confirmationDialog(copy.importData, isPresented: $confirmImport, titleVisibility: .visible) {
            Button(copy.importData, role: .destructive) {
                if store.importDocument(pendingImport) {
                    store.flash(copy.importDone)
                } else {
                    store.flash(copy.importInvalid)
                }
                pendingImport = ""
            }
            Button(copy.cancel, role: .cancel) { pendingImport = "" }
        } message: {
            Text(copy.importConfirm)
        }
        .confirmationDialog(copy.clearBook, isPresented: $confirmClear, titleVisibility: .visible) {
            Button(copy.clearBook, role: .destructive) {
                store.clearBook()
                store.flash(copy.clearBookDone)
            }
            Button(copy.cancel, role: .cancel) {}
        } message: {
            Text(copy.clearBookConfirm)
        }
    }

    private var divider: some View {
        Rectangle().fill(Palette.line.opacity(0.95)).frame(height: 1).padding(.vertical, 4)
    }

    private func budgetText(_ copy: LedgerCopy) -> String {
        if let budget = store.book.monthlyBudget, budget > 0 {
            return LedgerMoney.text(budget, mark: store.book.mark)
        }
        return copy.budgetUnset
    }

    private func settingsRow(_ title: String, trailing: String = "", opens: Bool = false, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(destructive ? Palette.down : Palette.ink)
                Spacer(minLength: 8)
                if !trailing.isEmpty {
                    Text(trailing)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Palette.muted)
                }
                if opens {
                    Text("›")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(Palette.muted)
                }
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
