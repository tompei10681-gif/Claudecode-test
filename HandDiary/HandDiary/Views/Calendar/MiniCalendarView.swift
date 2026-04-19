import SwiftUI

struct MiniCalendarView: View {
    @Binding var displayMonth: Date
    @Binding var selectedDate: Date
    let markedDates: Set<Date>

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        VStack(spacing: 8) {
            // Month navigation header
            HStack {
                Button {
                    displayMonth = calendar.date(byAdding: .month, value: -1, to: displayMonth) ?? displayMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.semibold))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthTitle)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Button {
                    displayMonth = calendar.date(byAdding: .month, value: 1, to: displayMonth) ?? displayMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }

            // Weekday headers
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdaySymbols.indices, id: \.self) { i in
                    Text(weekdaySymbols[i])
                        .font(.caption2)
                        .foregroundStyle(
                            i == 0 ? Color.red : i == 6 ? Color.blue : Color.secondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 4)
                }
            }

            // Day grid
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasEntry: markedDates.contains(calendar.startOfDay(for: date)),
                            weekday: calendar.component(.weekday, from: date)
                        ) {
                            selectedDate = date
                        }
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

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: displayMonth)
    }

    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        // weekday: 1=Sun, adjust to 0-indexed offset
        let offset = firstWeekday - 1

        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        // Pad to complete last row
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
                    .font(.caption2.weight(isToday || isSelected ? .bold : .regular))
                    .foregroundStyle(foregroundColor)
                    .frame(width: 28, height: 28)
                    .background(background)
                    .clipShape(Circle())

                Circle()
                    .fill(hasEntry ? Color.accentColor : Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        if isSelected { return .white }
        if isToday { return .accentColor }
        switch weekday {
        case 1: return .red
        case 7: return .blue
        default: return .primary
        }
    }

    private var background: some View {
        Group {
            if isSelected {
                Color.accentColor
            } else if isToday {
                Color.accentColor.opacity(0.15)
            } else {
                Color.clear
            }
        }
    }
}
