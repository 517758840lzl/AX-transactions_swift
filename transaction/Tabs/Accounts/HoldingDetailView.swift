//
//  HoldingDetailView.swift
//  transaction
//
//  Created by Lzl on 2026/10/22.
//

import Combine
import SwiftUI

struct HoldingDetailView: View {
    @ObservedObject var store: BookStore
    var holdingID: String
    @Environment(\.pageBack) private var pageBack

    var body: some View {
        let copy = store.copy
        if let holding = store.book.holdings.first(where: { $0.id == holdingID }) {
            let market = BookMath.holdingMarketValue(holding)
            let pnl = BookMath.holdingPnl(holding)
            FormPage(title: holding.name, back: copy.back) {
                PanelCard {
                    Text("\(holding.code) · \(copy.holdingKind(holding.kind))").foregroundStyle(Palette.muted)
                    MoneyText(value: market, mark: store.book.mark, size: 32)
                    row(copy.holdingPnl, LedgerMoney.text(pnl, mark: store.book.mark, signed: true))
                    row(copy.holdingQty, "\(holding.qty) \(copy.shareUnit(holding.kind))")
                    row(copy.holdingCostPrice, LedgerMoney.text(holding.qty == 0 ? 0 : holding.costTotal / holding.qty, mark: store.book.mark))
                    row(copy.holdingPrice, LedgerMoney.text(holding.price, mark: store.book.mark))
                    row(copy.holdingPriceAsOf, holding.priceAsOf)
                }
                HoldingEditLink(holdingID: holding.id, title: copy.editHolding)
            }
        } else {
            Color.white.onAppear { pageBack() }
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(Palette.muted)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
        .font(.system(size: 14))
    }
}
