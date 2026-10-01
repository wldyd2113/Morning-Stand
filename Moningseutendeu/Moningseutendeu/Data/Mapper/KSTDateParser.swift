import Foundation

/// 공공 API의 KST 날짜 문자열을 `Date`로 바꾼다. 소수점 초(`.0`)가 붙어도 된다.
nonisolated enum KSTDateParser {
    /// "2026-10-01 18:32:20", "2026-10-01 18:32:20.0" → Date
    static func dateTime(_ text: String?, calendar: Calendar) -> Date? {
        guard let text else { return nil }
        let numbers = text.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard numbers.count >= 5 else { return nil }
        var components = DateComponents()
        components.year = numbers[0]
        components.month = numbers[1]
        components.day = numbers[2]
        components.hour = numbers[3]
        components.minute = numbers[4]
        components.second = numbers.count > 5 ? numbers[5] : 0
        return calendar.date(from: components)
    }

    /// Date → "yyyyMMdd"
    static func compactDate(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d%02d%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}
