import Foundation

/// 다음 기상 알람 시각 → "내일 오전 6:50", "오늘 오전 6:50", "월요일 오전 6:50"
nonisolated enum WakeAlarmFormatter {
    static func text(for date: Date, now: Date, calendar: Calendar) -> String {
        let time = DisplayFormatter.meridiemTimeText(TimeOfDay(date: date, calendar: calendar), on: date, calendar: calendar)
        if calendar.isDate(date, inSameDayAs: now) { return String(localized: "오늘 \(time)") }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            return String(localized: "내일 \(time)")
        }
        let weekday = calendar.standaloneWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
        return "\(weekday) \(time)"
    }
}
