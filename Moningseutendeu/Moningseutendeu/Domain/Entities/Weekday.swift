import Foundation

/// 요일. `rawValue`는 `Calendar`의 weekday 번호(일요일 = 1)와 같다.
nonisolated enum Weekday: Int, Sendable, Hashable, CaseIterable, Codable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    /// 화면에 보여줄 순서 (월요일 시작)
    static let displayOrder: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    var isWeekend: Bool { self == .saturday || self == .sunday }
}
