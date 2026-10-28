import Combine
import SwiftUI

struct DashboardClaimPanel: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
    var copy: LedgerCopy

    var body: some View {
        let waiting = store.book.entries.filter { $0.claim == .waiting && $0.isOut }
        if !waiting.isEmpty {
            PanelCard(title: "\(copy.claimTitle) · \(waiting.count)") {
                ForEach(waiting) { entry in
                    HStack(spacing: 8) {
                        Button { screen.open(.entry(id: entry.id)) } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.title)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Palette.ink)
                                    .lineLimit(1)
                                Text(entry.category)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Palette.muted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        MoneyText(value: entry.amount, mark: store.book.mark, size: 14)
                        Button(copy.claimPaid) { store.payClaim(entry.id) }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Palette.pink, in: Capsule())
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
}
