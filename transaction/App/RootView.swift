//
//  RootView.swift
//  transaction
//
//  Created by Lzl on 2026/10/2.
//

import Combine
import SwiftUI

struct RootView: View {
    @StateObject private var store: BookStore
    @StateObject private var screen = LedgerScreen()
    @State private var opening = true

    init(store: BookStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        let copy = store.copy
        ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    ZStack {
                        Group {
                            switch screen.tab {
                            case 0: DashboardView(store: store, screen: screen)
                            case 1: TransactionsView(store: store, screen: screen)
                            case 2: AccountsView(store: store, screen: screen)
                            default: MeView(store: store, screen: screen)
                            }
                        }
                        .id(screen.tab)
                        .transition(.opacity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    tabBar(copy)
                }
                if screen.tab == 0 || screen.tab == 1 {
                    Button {
                        screen.open(.entry(id: nil))
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Palette.ink)
                            .frame(width: 56, height: 56)
                            .background(Palette.pink, in: Circle())
                    }
                    .padding(.trailing, 18)
                    .padding(.bottom, 78)
                    .accessibilityLabel(copy.entryNew)
                }
                if let note = store.note {
                    Text(note)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Palette.ink.opacity(0.92), in: Capsule())
                        .padding(.bottom, 96)
                        .frame(maxWidth: .infinity)
                }
                ForEach(Array(screen.path.enumerated()), id: \.offset) { index, page in
                    destination(page, copy: copy)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Palette.stage)
                        .zIndex(Double(index + 1))
                        .transition(.move(edge: .trailing))
                }
                if opening {
                    OpeningCover(line: store.book.locale.openingLine) {
                        withAnimation(.easeOut(duration: 0.32)) {
                            opening = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(40)
                }
            }
            .background(Palette.stage)
        .environmentObject(screen)
        .environment(\.pageBack, { screen.close() })
        .environment(\.keyboardDone, copy.done)
        .environment(\.amountsHidden, store.book.hideAmounts)
        .onAppear {
            store.settleRepeats()
        }
        .tint(Palette.ink)
    }

    @ViewBuilder
    private func destination(_ page: Page, copy: LedgerCopy) -> some View {
        switch page {
        case .entry(let id):
            EntryFormView(store: store, entryID: id)
        case .filter(let which):
            FilterFormView(store: store, screen: screen, which: which)
        case .budget:
            BudgetFormView(store: store)
        case .account(let id):
            AccountDetailView(store: store, screen: screen, accountID: id)
        case .accountForm(let id):
            AccountFormView(store: store, accountID: id)
        case .holding(let id):
            HoldingDetailView(store: store, holdingID: id)
        case .holdingForm(let id):
            HoldingFormView(store: store, holdingID: id)
        case .transfer:
            TransferFormView(store: store)
        case .repeatPlan(let id):
            RepeatPlanFormView(store: store, planID: id)
        case .yearReport:
            YearReportPage(store: store, screen: screen)
        case .savingGoals:
            SavingGoalsListView(store: store, screen: screen)
        case .savingGoal(let id):
            SavingGoalFormView(store: store, goalID: id)
        case .profile:
            ProfileFormView(store: store)
        case .categories:
            CategoryManageView(store: store)
        case .language:
            LanguagePickView(store: store)
        case .currency:
            CurrencyPickView(store: store)
        case .privacy:
            PrivacyView(title: copy.privacyTitle)
        case .export:
            BookExportPage(store: store, screen: screen)
        case .removed:
            RemovedListView(store: store)
        case .worthTrend:
            WorthTrendPage(store: store, screen: screen)
        }
    }

    private func tabBar(_ copy: LedgerCopy) -> some View {
        let labels = [copy.tabDashboard, copy.tabTransactions, copy.tabAccounts, copy.tabMe]
        let icons = ["square.grid.2x2", "list.bullet", "wallet.pass", "person"]
        return HStack(spacing: 0) {
            ForEach(labels.indices, id: \.self) { index in
                Button {
                    screen.selectTab(index)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: icons[index])
                            .font(.system(size: 18))
                            .foregroundStyle(Palette.ink)
                            .padding(screen.tab == index ? 4 : 0)
                            .background(screen.tab == index ? Palette.pink : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                        Text(labels[index])
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(screen.tab == index ? Palette.ink : Palette.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
        .background(Color.white)
    }
}
