//
//  QCMeView.swift
//  transaction
//
//  Created by Lzl on 2026/10/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct QCMeView: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen
    @State private var pickingFile = false
    @State private var pendingImport = ""
    @State private var confirmImport = false
    @State private var confirmClear = false

    var body: some View {
        let copy = store.copy
        let streak = QCBookMath.streakDays(store.book.entries)
        let logged = QCBookMath.loggedToday(store.book.entries)
        let name = store.book.nickname.isEmpty ? copy.unsetName : store.book.nickname
        let languageName = store.book.locale.title
        VStack(alignment: .leading, spacing: 0) {
        Text(copy.me).font(.system(size: 26, weight: .bold)).tracking(-0.4).foregroundStyle(QCPalette.ink)
            .pageTitleBar()
        QCPageScroll(place: "me", bottom: 16) {
            QCPanelCard(card: true) {
                Button { screen.open(.profile) } label: {
                    HStack(spacing: 14) {
                        QCAvatarMark(gender: store.book.gender, size: 56)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(name)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(QCPalette.ink)
                                    .lineLimit(1)
                                if !store.book.nickname.isEmpty {
                                    Image(systemName: genderSymbol(store.book.gender))
                                        .font(.system(size: 16))
                                        .foregroundStyle(QCPalette.muted)
                                        .accessibilityLabel(copy.genderName(store.book.gender))
                                }
                            }
                            if store.book.nickname.isEmpty {
                                Text(copy.profileHint).font(.system(size: 13)).foregroundStyle(QCPalette.muted)
                            }
                            Text("\(copy.streakDays) \(streak) · \(logged ? copy.streakToday : copy.streakNone)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(QCPalette.muted)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            QCPanelCard(card: true) {
                QCRecordMarkCard(days: QCBookMath.loggedDays(store.book.entries), copy: copy) {
                    screen.openNewRecord(store: store)
                }
            }

            QCPanelCard(title: copy.meLedger, titleSize: 13, card: true) {
                settingsRow(copy.accounts, trailing: "\(store.book.accounts.filter { !$0.id.hasPrefix("sample-") }.count)", opens: true) {
                    screen.open(.accountsHome)
                }
                divider
                settingsRow(copy.yearReport, opens: true) { screen.open(.yearReport) }
                divider
                settingsRow(copy.monthlyBudget, trailing: budgetText(copy), opens: true) { screen.open(.budget) }
                divider
                settingsRow(copy.savingGoals, trailing: store.book.goals.isEmpty ? "" : "\(store.book.goals.count)", opens: true) { screen.open(.savingGoals) }
                divider
                settingsRow(copy.categories, trailing: "\(store.book.categories.count)", opens: true) { screen.open(.categories) }
            }

            QCPanelCard(title: copy.meDisplay, titleSize: 13, card: true) {
                settingsRow(copy.hideAmounts, trailing: store.book.hideAmounts ? copy.hideAmountsOn : copy.hideAmountsOff) {
                    store.setHideAmounts(!store.book.hideAmounts)
                }
                divider
                settingsRow(copy.language, trailing: languageName, opens: true) { screen.open(.language) }
                divider
                settingsRow(copy.currency, trailing: "\(store.book.currency.rawValue) \(store.book.mark)", opens: true) { screen.open(.currency) }
                divider
                settingsRow(copy.reminderTitle, trailing: reminderText(copy), opens: true) { screen.open(.reminder) }
            }

            QCPanelCard(title: copy.meData, titleSize: 13, card: true) {
                settingsRow(copy.cloudTitle, trailing: cloudTrailing(copy), opens: true) { screen.open(.cloud) }
                divider
                settingsRow(copy.exportBook, opens: true) { screen.open(.export) }
                divider
                settingsRow(copy.importData, opens: true) { pickingFile = true }
                divider
                settingsRow(copy.removedTitle, trailing: store.book.removed.isEmpty ? "" : "\(store.book.removed.count)", opens: true) {
                    screen.open(.removed)
                }
                divider
                settingsRow(copy.clearBook, opens: true, destructive: true) { confirmClear = true }
            }

            QCPanelCard(card: true) {
                settingsRow(copy.about, opens: true) { screen.open(.about) }
                divider
                settingsRow(copy.disclaimer, opens: true) { screen.open(.disclaimer) }
                divider
                settingsRow(copy.privacy, opens: true) { screen.open(.privacy) }
            }
        }
        }
        .fileImporter(isPresented: $pickingFile, allowedContentTypes: [.json, .plainText]) { result in
            guard case .success(let url) = result, url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            let text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            guard QCBookDocument.decode(text) != nil else {
                store.flash(store.copy.importInvalid)
                return
            }
            pendingImport = text
            confirmImport = true
        }
        .alert(copy.importData, isPresented: $confirmImport) {
            Button(copy.cancel, role: .cancel) { pendingImport = "" }
            Button(copy.importData, role: .destructive) {
                if store.importDocument(pendingImport) {
                    store.flash(copy.importDone)
                } else {
                    store.flash(copy.importInvalid)
                }
                pendingImport = ""
            }
        } message: {
            Text(copy.importConfirm)
        }
        .alert(copy.clearBook, isPresented: $confirmClear) {
            Button(copy.cancel, role: .cancel) {}
            Button(copy.clearBook, role: .destructive) {
                store.clearBook()
                store.flash(copy.clearBookDone)
            }
        } message: {
            Text(copy.clearBookConfirm)
        }
    }

    private var divider: some View {
        Rectangle().fill(QCPalette.line.opacity(0.95)).frame(height: 1).padding(.vertical, 4)
    }

    private func cloudTrailing(_ copy: QCLedgerCopy) -> String {
        guard let on = store.cloudOn else { return "" }
        if !on { return copy.cloudOff }
        guard let when = store.cloudWhen else { return copy.cloudNone }
        return store.cloudClock(when)
    }

    private func reminderText(_ copy: QCLedgerCopy) -> String {
        guard store.book.dailyReminder else { return copy.reminderOff }
        return String(format: "%02d:%02d", store.book.reminderHour, store.book.reminderMinute)
    }

    private func budgetText(_ copy: QCLedgerCopy) -> String {
        if let budget = store.book.monthlyBudget, budget > 0 {
            return QCLedgerMoney.text(budget, mark: store.book.mark)
        }
        return copy.budgetUnset
    }

    private func settingsRow(_ title: String, trailing: String = "", opens: Bool = false, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(destructive ? QCPalette.down : QCPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 8)
                if !trailing.isEmpty {
                    Text(trailing)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(QCPalette.muted)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                if opens {
                    Text("›")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(QCPalette.muted)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func genderSymbol(_ gender: QCGender) -> String {
        switch gender {
        case .female: return "figure.stand.dress"
        case .male: return "figure.stand"
        case .secret: return "lock"
        }
    }
}
