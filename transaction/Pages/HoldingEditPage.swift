import Combine
import SwiftUI

struct HoldingFormView: View {
    @ObservedObject var store: BookStore
    var holdingID: String?
    @Environment(\.pageBack) private var pageBack
    @State private var kind = HoldingKind.stock
    @State private var code = ""
    @State private var name = ""
    @State private var qty = ""
    @State private var cost = ""
    @State private var price = ""
    @State private var priceDate = LedgerDay.today()
    @State private var ready = false

    var body: some View {
        let copy = store.copy
        let editing = store.book.holdings.contains { $0.id == holdingID }
        FormPage(title: editing ? copy.editHolding : copy.newHolding, back: copy.back) {
            FieldLabel(text: copy.holdingKindLabel)
            ChoiceRow(labels: HoldingKind.allCases.map { copy.holdingKind($0) }, index: HoldingKind.allCases.firstIndex(of: kind) ?? 0) { index in
                kind = HoldingKind.allCases[index]
            }
            FieldLabel(text: copy.holdingCode)
            LedgerField(text: $code, placeholder: hintCode(copy))
            FieldLabel(text: copy.holdingName)
            LedgerField(text: $name, placeholder: hintName(copy))
            FieldLabel(text: copy.holdingQty)
            LedgerField(text: $qty, placeholder: "0", decimal: true)
            FieldLabel(text: copy.holdingCostPrice)
            LedgerField(text: $cost, placeholder: copy.holdingCostPricePh, decimal: true)
            FieldLabel(text: copy.holdingPrice)
            LedgerField(text: $price, placeholder: "0.00", decimal: true)
            FieldLabel(text: copy.holdingPriceAsOf)
            DatePicker(copy.holdingPriceAsOf, selection: Binding(get: { LedgerDay.parse(priceDate) }, set: { priceDate = LedgerDay.iso($0) }), in: ...Date(), displayedComponents: .date)
                .labelsHidden()
            PillButton(title: copy.save, enabled: canSave) { save() }
            if editing {
                Button(copy.deleteHolding) {
                    if let holdingID { store.removeHolding(holdingID) }
                    pageBack()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.review)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            guard !ready else { return }
            ready = true
            if let holding = store.book.holdings.first(where: { $0.id == holdingID }) {
                kind = holding.kind
                code = holding.code
                name = holding.name
                qty = String(holding.qty)
                cost = holding.qty == 0 ? "" : LedgerMoney.fixed(holding.costTotal / holding.qty, fraction: 2)
                price = LedgerMoney.fixed(holding.price, fraction: 2)
                priceDate = holding.priceAsOf
            }
        }
    }

    private func hintCode(_ copy: LedgerCopy) -> String {
        switch kind {
        case .stock: return copy.holdingCodeStock
        case .etf: return copy.holdingCodeEtf
        case .fund: return copy.holdingCodeFund
        }
    }

    private func hintName(_ copy: LedgerCopy) -> String {
        switch kind {
        case .stock: return copy.holdingNameStock
        case .etf: return copy.holdingNameEtf
        case .fund: return copy.holdingNameFund
        }
    }

    private var canSave: Bool {
        let quantity = Double(qty)
        let costValue = Double(cost)
        let priceValue = Double(price)
        return !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (quantity ?? 0) > 0
            && (costValue ?? -1) >= 0
            && (priceValue ?? 0) > 0
    }

    private func save() {
        guard canSave, let quantity = Double(qty), let costValue = Double(cost), let priceValue = Double(price) else { return }
        let holding = Holding(
            id: holdingID ?? LedgerID.make(),
            kind: kind,
            code: code.trimmingCharacters(in: .whitespacesAndNewlines),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            qty: quantity,
            costTotal: LedgerMoney.cents(quantity * costValue),
            price: LedgerMoney.cents(priceValue),
            priceAsOf: priceDate
        )
        if store.upsertHolding(holding) { pageBack() }
    }
}
