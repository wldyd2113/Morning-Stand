import Foundation

/// 협탁 기상 알람. 정해진 요일·시각에 매주 반복해서 울린다.
nonisolated struct WakeAlarmSetting: Sendable, Equatable, Codable {
    var isEnabled: Bool
    var time: TimeOfDay
    /// 울릴 요일 (월요일 시작 순서)
    var weekdays: [Weekday]

    static let `default` = WakeAlarmSetting(
        isEnabled: false,
        time: TimeOfDay(hour: 7, minute: 0),
        weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday]
    )

    /// `now` 이후 처음 울릴 시각. 꺼져 있거나 요일이 없으면 nil
    func nextOccurrence(after now: Date, calendar: Calendar) -> Date? {
        guard isEnabled, !weekdays.isEmpty else { return nil }
        for dayOffset in 0...Weekday.allCases.count {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now),
                  let weekday = Weekday(rawValue: calendar.component(.weekday, from: day)),
                  weekdays.contains(weekday) else { continue }
            let candidate = time.date(on: day, calendar: calendar)
            if candidate > now { return candidate }
        }
        return nil
    }
}
