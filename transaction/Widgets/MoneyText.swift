import SwiftUI

struct MoneyText: View {
    var value: Double
    var mark: String
    var size: CGFloat = 16
    var signed = false
    var color: Color = Palette.ink

    var body: some View {
        let negative = value < 0
        let sign = signed && value > 0 ? "+" : (negative ? "−" : "")
        let digits: Font.Weight = size >= 16 ? .bold : .semibold
        return (
            Text(sign + mark).font(.system(size: size, weight: .semibold))
                + Text(LedgerMoney.body(value)).font(.system(size: size, weight: digits))
        )
        .foregroundStyle(color)
        .monospacedDigit()
    }
}
