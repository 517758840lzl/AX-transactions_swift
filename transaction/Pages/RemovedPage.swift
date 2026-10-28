import SwiftUI

struct RemovedListView: View {
    @ObservedObject var store: BookStore

    var body: some View {
        let copy = store.copy
        FormPage(title: copy.removedTitle, back: copy.back) {
            PanelCard(card: true) {
                if store.book.removed.isEmpty {
                    Text(copy.removedEmpty)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                ForEach(Array(store.book.removed.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Rectangle().fill(Palette.line).frame(height: 1)
                    }
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.entry.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Palette.ink)
                                .lineLimit(1)
                            Text(copy.dayChip(item.removedOn))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Palette.muted)
                        }
                        Spacer(minLength: 8)
                        MoneyText(
                            value: item.entry.amount,
                            mark: store.book.mark,
                            size: 15,
                            color: item.entry.isOut ? Palette.down : Palette.up
                        )
                        Button(copy.removedRestore) { store.restoreEntry(item.id) }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Palette.pink, in: Capsule())
                    }
                    .padding(.vertical, 10)
                }
            }
        }
    }
}
