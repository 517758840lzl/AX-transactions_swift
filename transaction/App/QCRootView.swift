//
//  QCRootView.swift
//  transaction
//
//  Created by Lzl on 2026/10/2.
//

import SwiftUI
import UIKit

struct QCRootView: View {
    @StateObject private var store: QCBookStore
    @StateObject private var screen = QCLedgerScreen()
    @Environment(\.scenePhase) private var scenePhase
    @State private var opening = true
    @State private var guide = !QCGuideDeck.alreadySeen
    @State private var edgeDrag: CGFloat = 0
    @State private var edgePage = -1
    @State private var edgeTicket = 0

    init(store: QCBookStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        let copy = store.copy
        ZStack(alignment: .bottomTrailing) {
                Group {
                    switch screen.tab {
                    case 0: QCDashboardView(store: store, screen: screen)
                    case 1: QCTransactionsView(store: store, screen: screen)
                    case 2: QCSparkHomeView(store: store, screen: screen)
                    default: QCMeView(store: store, screen: screen)
                    }
                }
                .id(screen.tab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    tabBar(copy)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                if screen.path.isEmpty, screen.tab == 0 || screen.tab == 1 {
                    QCEntryButton(title: copy.entryNew) {
                        screen.openNewRecord(store: store)
                    }
                }
                if let note = store.note {
                    Text(note)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(QCPalette.ink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.white, in: Capsule())
                        .overlay(Capsule().stroke(QCPalette.line, lineWidth: 1))
                        .shadow(color: QCPalette.ink.opacity(0.08), radius: 12, y: 6)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                        .zIndex(25)
                }
                ForEach(Array(screen.path.enumerated()), id: \.offset) { index, page in
                    destination(page, copy: copy)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(QCPalette.stage)
                        .offset(x: index == edgePage ? edgeDrag : 0)
                        .background {
                            if index == screen.path.count - 1 {
                                QCEdgeBack(onChange: { moved in
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
                if !opening && !guide, coverStatusBar {
                    statusBarCover
                        .zIndex(30)
                }
                if opening {
                    QCOpeningCover(line: store.book.locale.openingLine) {
                        withAnimation(.easeOut(duration: 0.32)) {
                            opening = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(40)
                } else if guide {
                    QCGuideDeck {
                        QCGuideDeck.markSeen()
                        withAnimation(.easeOut(duration: 0.32)) {
                            guide = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(40)
                }
            }
            .background(QCPalette.stage)
        .environmentObject(screen)
        .environment(\.pageBack, { screen.close() })
        .environment(\.amountsHidden, store.book.hideAmounts)
        .onAppear {
            store.settleRepeats()
            QCBillReminder.shared.refresh(book: store.book)
            QCDailyReminder.shared.sync(store.book, ask: false)
            openPendingBill()
            openPendingEntry()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                QCBillReminder.shared.refresh(book: store.book)
                QCDailyReminder.shared.sync(store.book, ask: false)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .billReminderOpened)) { _ in
            openPendingBill()
        }
        .onReceive(NotificationCenter.default.publisher(for: .dailyLogOpened)) { _ in
            openPendingEntry()
        }
        .tint(QCPalette.ink)
    }

    /// The writing page paints its own color through the status bar.
    private var coverStatusBar: Bool {
        if case .spark = screen.path.last { return false }
        return true
    }

    /// Covers the status bar with the page color so scrolling cards do not show through it.
    private var statusBarCover: some View {
        let height = Self.statusBarHeight
        return statusCoverFill
            .frame(height: height)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .offset(y: -height)
            .allowsHitTesting(false)
    }

    private var statusCoverFill: Color {
        switch screen.path.last {
        case .yearReport, .reminder, .accountsHome, .about, .disclaimer, nil:
            return QCPalette.stage
        default:
            return .white
        }
    }

    private static var statusBarHeight: CGFloat {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            if let window = scene.windows.first(where: \.isKeyWindow) {
                return max(window.safeAreaInsets.top, 20)
            }
        }
        return max(scenes.first?.windows.first?.safeAreaInsets.top ?? 47, 20)
    }

    private func finishEdge(from index: Int, moved: CGFloat, speed: CGFloat) {
        let width = UIScreen.main.bounds.width
        let commit = moved > width * 0.3 || speed > 900
        guard commit else {
            withAnimation(QCLedgerScreen.pageSlide) {
                edgeDrag = 0
                edgePage = -1
            }
            return
        }
        edgeTicket += 1
        let ticket = edgeTicket
        let depth = screen.path.count
        withAnimation(QCLedgerScreen.pageSlide) {
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
        guard let id = QCBillReminder.shared.takePendingAccountID() else { return }
        if case .account(let showing) = screen.path.last, showing == id { return }
        screen.open(.account(id: id))
    }

    private func openPendingEntry() {
        guard QCBillReminder.shared.takePendingEntry() else { return }
        if case .entry = screen.path.last { return }
        screen.statsKind = "out"
        screen.openNewRecord(store: store)
    }

    @ViewBuilder
    private func destination(_ page: QCPage, copy: QCLedgerCopy) -> some View {
        switch page {
        case .entry(let id):
            QCEntryFormView(store: store, screen: screen, entryID: id)
        case .filter(let which):
            QCFilterFormView(store: store, screen: screen, which: which)
        case .budget:
            QCBudgetFormView(store: store)
        case .account(let id):
            QCAccountDetailView(store: store, screen: screen, accountID: id)
        case .accountForm(let id, let chooseKind):
            QCAccountFormView(store: store, accountID: id, chooseKind: chooseKind)
        case .transfer:
            QCTransferFormView(store: store)
        case .repeatPlan(let id):
            QCRepeatPlanFormView(store: store, screen: screen, planID: id)
        case .yearReport:
            QCYearReportPage(store: store, screen: screen)
        case .savingGoals:
            QCSavingGoalsListView(store: store, screen: screen)
        case .savingGoal(let id):
            QCSavingGoalFormView(store: store, goalID: id)
        case .sparks:
            QCSparkHomeView(store: store, screen: screen)
        case .sparkShelf(let kind):
            QCSparksListView(store: store, screen: screen, kind: kind)
        case .sparkBoard:
            QCSparkBoardView(store: store, screen: screen)
        case .accountsHome:
            QCAccountsView(store: store, screen: screen)
        case .spark(let id):
            QCSparkFormView(store: store, screen: screen, sparkID: id)
        case .profile:
            QCProfileFormView(store: store)
        case .categories:
            QCCategoryManageView(store: store, screen: screen)
        case .categoryForm(let slot):
            QCCategoryFormView(store: store, screen: screen, slot: slot)
        case .language:
            QCLanguagePickView(store: store)
        case .currency:
            QCCurrencyPickView(store: store)
        case .privacy:
            QCPrivacyView(title: copy.privacyTitle)
        case .about:
            QCAboutPage(copy: copy)
        case .disclaimer:
            QCDisclaimerPage(copy: copy)
        case .reminder:
            QCReminderPage(store: store)
        case .export:
            QCBookExportPage(store: store, screen: screen)
        case .cloud:
            QCCloudPage(store: store)
        case .removed:
            QCRemovedListView(store: store)
        case .worthTrend:
            QCWorthTrendPage(store: store, screen: screen)
        }
    }

    private func tabBar(_ copy: QCLedgerCopy) -> some View {
        let labels = [copy.tabDashboard, copy.tabTransactions, copy.sparks, copy.tabMe]
        let icons = ["TabOverview", "TabLedger", "TabAccounts", "TabProfile"]
        return HStack(spacing: 0) {
            ForEach(labels.indices, id: \.self) { index in
                Button {
                    screen.selectTab(index)
                } label: {
                    VStack(spacing: 4) {
                        Image(icons[index])
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(QCPalette.ink)
                            .padding(screen.tab == index ? 4 : 0)
                            .background(screen.tab == index ? QCPalette.pink : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                        Text(labels[index])
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(screen.tab == index ? QCPalette.ink : QCPalette.muted)
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
        .background(Color.white.ignoresSafeArea(edges: .bottom))
    }
}
