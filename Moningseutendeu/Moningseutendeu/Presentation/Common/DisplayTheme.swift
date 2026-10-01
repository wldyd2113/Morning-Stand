import Foundation

/// 스탠드 화면 테마. 시스템 다크 모드와 별개로 시각에 따라 바뀐다.
nonisolated enum DisplayTheme: String, Sendable, Equatable {
    case day
    case night

    /// 22시~6시(PolicyConstants.NightTheme)는 저휘도 야간 테마.
    static func resolve(at date: Date, calendar: Calendar) -> DisplayTheme {
        let hour = calendar.component(.hour, from: date)
        let isNight = hour >= PolicyConstants.NightTheme.startHour || hour < PolicyConstants.NightTheme.endHour
        return isNight ? .night : .day
    }
}
