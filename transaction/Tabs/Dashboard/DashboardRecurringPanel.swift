import Combine
import SwiftUI

struct DashboardRecurringPanel: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
    var copy: LedgerCopy
    var items: [RecurringItem]

    var body: some View {
        if items.isEmpty {
            PanelCard(title: copy.recurringTitle, trailing: {
                Button(copy.entryNew) { screen.open(.entry(id: nil)) }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.ink)
            }) {
                Text(copy.recurringEmpty)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            PanelCard(title: copy.recurringTitle, trailing: {
                Text(copy.recurringHint)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.trailing)
            }) {
                ForEach(items) { item in
                    Button {
                        if let entry = store.book.entries.first(where: { $0.title == item.title && $0.amount == item.amount }) {
                            screen.open(.entry(id: entry.id))
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(item.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Palette.ink)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text("\(item.times)× · ")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Palette.muted)
                            MoneyText(value: item.amount, mark: store.book.mark, size: 13)
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
