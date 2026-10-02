import Foundation

/// 여러 화면에서 같이 쓰는 날짜·시간·거리 표시 문구. 전부 `Calendar.seoul` 기준 순수 함수.
nonisolated enum DisplayFormatter {
    private static func baseStyle(_ calendar: Calendar) -> Date.FormatStyle {
        Date.FormatStyle(locale: calendar.locale ?? Locale(identifier: AppConstants.Region.localeIdentifier), calendar: calendar, timeZone: calendar.timeZone)
    }

    /// "9월 30일 수요일"
    static func dateText(for date: Date, calendar: Calendar) -> String {
        date.formatted(baseStyle(calendar).month(.wide).day(.defaultDigits).weekday(.wide))
    }

    /// "9월 30일 (수)"
    static func shortDateText(for date: Date, calendar: Calendar) -> String {
        let day = date.formatted(baseStyle(calendar).month(.wide).day(.defaultDigits))
        let weekday = date.formatted(baseStyle(calendar).weekday(.abbreviated))
        return "\(day) (\(weekday))"
    }

    /// "오후 6시"
    static func hourText(hour: Int, on day: Date, calendar: Calendar) -> String {
        TimeOfDay(hour: hour, minute: 0)
            .date(on: day, calendar: calendar)
            .formatted(baseStyle(calendar).hour(.defaultDigits(amPM: .abbreviated)))
    }

    /// "오전 8:10"
    static func meridiemTimeText(_ time: TimeOfDay, on day: Date, calendar: Calendar) -> String {
        time.date(on: day, calendar: calendar)
            .formatted(baseStyle(calendar).hour(.defaultDigits(amPM: .abbreviated)).minute(.twoDigits))
    }

    /// "12초 전", "25분 전", "2시간 전". 미래 시각이면 "방금".
    static func elapsedText(from start: Date, to end: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.hour, .minute, .second], from: start, to: end)
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        let seconds = components.second ?? 0
        if hours > 0 { return String(localized: "\(hours)시간 전") }
        if minutes > 0 { return String(localized: "\(minutes)분 전") }
        if seconds > 0 { return String(localized: "\(seconds)초 전") }
        return String(localized: "방금")
    }

    /// "380m", "1.2km"
    static func distanceText(meters: Int) -> String {
        let measurement = Measurement(value: Double(meters), unit: UnitLength.meters)
        let kilometers = measurement.converted(to: .kilometers)
        if kilometers.value < 1 {
            return "\(meters)m"
        }
        return kilometers.value.formatted(.number.precision(.fractionLength(1))) + "km"
    }
}
