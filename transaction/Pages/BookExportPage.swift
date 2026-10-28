import Combine
import SwiftUI

struct DataView: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
    @Environment(\.pageBack) private var pageBack
    @State private var confirmClear = false

    var body: some View {
        let copy = store.copy
        let book = store.book
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SubpageHead(title: copy.dataManage, back: copy.back) { pageBack() }
                summary(copy, book: book)
                exportCard(copy)
                clearCard(copy)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 32)
            .immediateScroll()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.stage)
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

    private func summary(_ copy: LedgerCopy, book: Book) -> some View {
        PanelCard {
            HStack(spacing: 0) {
                stat(book.entries.count, copy.transactions) { showTab(1) }
                Rectangle().fill(Palette.line).frame(width: 1, height: 36)
                stat(book.accounts.count, copy.accounts) { showTab(2) }
                Rectangle().fill(Palette.line).frame(width: 1, height: 36)
                stat(book.holdings.count, copy.holdingsLabel) { showTab(2) }
            }
        }
    }

    private func stat(_ count: Int, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func exportCard(_ copy: LedgerCopy) -> some View {
        Button {
            ShareSheet.present(store.exportText())
        } label: {
            PanelCard {
                HStack(spacing: 14) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                        .frame(width: 44, height: 44)
                        .background(Palette.pink, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(copy.exportBackup)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Palette.ink)
                        Text(copy.dataExportNote)
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.faint)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func clearCard(_ copy: LedgerCopy) -> some View {
        PanelCard {
            Text(copy.clearBook)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Palette.down)
            Text(copy.clearBookConfirm)
                .font(.system(size: 13))
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
            Button(copy.clearBook) { confirmClear = true }
                .buttonStyle(.plain)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.down)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Palette.wash, in: Capsule())
                .padding(.top, 14)
        }
    }

    private func showTab(_ index: Int) {
        screen.tab = index
        screen.path = []
    }
}
