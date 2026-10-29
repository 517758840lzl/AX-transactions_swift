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
    @Environment(\.scenePhase) private var scenePhase
    @State private var opening = true
    @State private var edgeDrag: CGFloat = 0
    @State private var edgePage = -1
    @State private var edgeTicket = 0

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
                    EntryButton(title: copy.entryNew) {
                        screen.open(.entry(id: nil))
                    }
                    .zIndex(5)
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
                        .offset(x: index == edgePage ? edgeDrag : 0)
                        .background {
                            if index == screen.path.count - 1 {
                                EdgeBack(onChange: { moved in
                                    edgePage = index
                                    edgeDrag = moved
                                }, onEnd: { moved, speed in
                                    finishEdge(from: index, moved: moved, speed: speed)
                                })
                            }
                        }
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
            BillReminder.shared.refresh(book: store.book)
            openPendingBill()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                BillReminder.shared.refresh(book: store.book)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .billReminderOpened)) { _ in
            openPendingBill()
        }
        .tint(Palette.ink)
    }

    private func finishEdge(from index: Int, moved: CGFloat, speed: CGFloat) {
        let width = UIScreen.main.bounds.width
        let commit = moved > width * 0.3 || speed > 900
        guard commit else {
            withAnimation(LedgerScreen.pageSlide) {
                edgeDrag = 0
                edgePage = -1
            }
            return
        }
        edgeTicket += 1
        let ticket = edgeTicket
        let depth = screen.path.count
        withAnimation(LedgerScreen.pageSlide) {
            edgePage = index
            edgeDrag = width
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            guard ticket == edgeTicket, screen.path.count == depth else { return }
            screen.close(animated: false)
            edgeDrag = 0
            edgePage = -1
        }
    }

    private func openPendingBill() {
        guard let id = BillReminder.shared.takePendingAccountID() else { return }
        if case .account(let showing) = screen.path.last, showing == id { return }
        screen.open(.account(id: id))
    }

    @ViewBuilder
    private func destination(_ page: Page, copy: LedgerCopy) -> some View {
        switch page {
        case .entry(let id):
            EntryFormView(store: store, screen: screen, entryID: id)
        case .filter(let which):
            FilterFormView(store: store, screen: screen, which: which)
        case .budget:
            BudgetFormView(store: store)
        case .account(let id):
            AccountDetailView(store: store, screen: screen, accountID: id)
        case .accountForm(let id, let chooseKind):
            AccountFormView(store: store, accountID: id, chooseKind: chooseKind)
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
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
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
