import SwiftUI

struct MiniCalendarView: View {
    @Binding var displayMonth: Date
    @Binding var selectedDate: Date
    let markedDates: Set<Date>

    private let cal = Calendar.current
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Button { shift(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.semibold))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthTitle)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Button { shift(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }

            // Weekday labels
            LazyVGrid(columns: cols, spacing: 0) {
                ForEach(weekdays.indices, id: \.self) { i in
                    Text(weekdays[i])
                        .font(.caption2)
                        .foregroundStyle(i == 0 ? .red : i == 6 ? .blue : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 4)
                }
            }

            // Days
            LazyVGrid(columns: cols, spacing: 2) {
                ForEach(daysInMonth.indices, id: \.self) { i in
                    if let date = daysInMonth[i] {
                        DayCell(
                            date: date,
                            isSelected: cal.isDate(date, inSameDayAs: selectedDate),
                            isToday: cal.isDateInToday(date),
                            hasEntry: markedDates.contains(cal.startOfDay(for: date)),
                            weekday: cal.component(.weekday, from: date)
                        ) { selectedDate = date }
                    } else {
                        Color.clear.frame(height: 32)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func shift(_ value: Int) {
        displayMonth = cal.date(byAdding: .month, value: value, to: displayMonth) ?? displayMonth
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月"
        return f.string(from: displayMonth)
    }

    private var daysInMonth: [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: displayMonth),
              let first = cal.date(from: cal.dateComponents([.year, .month], from: displayMonth))
        else { return [] }

        var days: [Date?] = Array(repeating: nil, count: cal.component(.weekday, from: first) - 1)
        for day in range {
            days.append(cal.date(byAdding: .day, value: day - 1, to: first))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEntry: Bool
    let weekday: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption2.weight(isSelected || isToday ? .bold : .regular))
                    .foregroundStyle(textColor)
                    .frame(width: 28, height: 28)
                    .background(bg)
                    .clipShape(Circle())

                Circle()
                    .fill(hasEntry ? Color.accentColor : .clear)
                    .frame(width: 4, height: 4)
            }
        }
        .buttonStyle(.plain)
    }

    private var textColor: Color {
        if isSelected { return .white }
        if isToday { return .accentColor }
        return weekday == 1 ? .red : weekday == 7 ? .blue : .primary
    }

    private var bg: some View {
        Group {
            if isSelected { Color.accentColor }
            else if isToday { Color.accentColor.opacity(0.15) }
            else { Color.clear }
        }
    }
}
