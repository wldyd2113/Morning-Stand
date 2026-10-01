import Foundation

/// 날짜 없이 "시:분"만 표현하는 값. 루틴 출발 시각, 첫차·막차 시각에 쓴다.
nonisolated struct TimeOfDay: Sendable, Hashable, Comparable, Codable {
    private static let minutesPerHour = 60
    private static let minutesPerDay = 24 * minutesPerHour

    let hour: Int
    let minute: Int

    init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    init(date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }

    private var minutesSinceMidnight: Int { hour * Self.minutesPerHour + minute }

    /// 분을 더한 시각. 자정을 넘기면 다음 날 시각으로 돌아간다.
    func adding(minutes: Int) -> TimeOfDay {
        let total = (minutesSinceMidnight + minutes) % Self.minutesPerDay
        let wrapped = total < 0 ? total + Self.minutesPerDay : total
        return TimeOfDay(hour: wrapped / Self.minutesPerHour, minute: wrapped % Self.minutesPerHour)
    }

    /// 24시간제 "HH:mm" 문자열.
    var text: String { String(format: "%02d:%02d", hour, minute) }

    /// 기준 날짜의 같은 시각. 표시용 포매팅에 쓴다.
    func date(on day: Date, calendar: Calendar) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
        lhs.minutesSinceMidnight < rhs.minutesSinceMidnight
    }
}
