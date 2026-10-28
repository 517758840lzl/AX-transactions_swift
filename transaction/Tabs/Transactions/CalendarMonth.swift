import Combine
import SwiftUI

struct CalendarMonth: View {
    var copy: LedgerCopy
    var spend: [String: Double]
    var selected: String
    var onSelect: (String) -> Void

    var body: some View {
        let calendar = Calendar.current
        let today = Date()
        let parts = calendar.dateComponents([.year, .month], from: today)
        let first = calendar.date(from: DateComponents(year: parts.year, month: parts.month, day: 1)) ?? today
        let weekday = calendar.component(.weekday, from: first) - 1
        let count = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
        PanelCard(title: copy.monthUnit(parts.month ?? 1)) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(copy.calendarWeek.indices, id: \.self) { index in
                    Text(copy.calendarWeek[index]).font(.system(size: 11, weight: .semibold)).foregroundStyle(Palette.muted)
                }
                ForEach(0..<weekday, id: \.self) { _ in Color.clear.frame(height: 28) }
                ForEach(1...count, id: \.self) { day in
                    let iso = LedgerDay.iso(year: parts.year ?? 0, month: parts.month ?? 1, day: day)
                    Button {
                        onSelect(iso)
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(day)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(iso == selected ? Color.white : Palette.ink)
                            Circle()
                                .fill((spend[iso] ?? 0) > 0 ? (iso == selected ? Color.white : Palette.pink) : Color.clear)
                                .frame(width: 4, height: 4)
                        }
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(iso == selected ? Palette.ink : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
