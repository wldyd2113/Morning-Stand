import Foundation

/// 요일별 출근 루틴.
nonisolated struct RoutineSetting: Sendable, Equatable, Codable {
    var weekday: Weekday
    var isEnabled: Bool
    var departure: TimeOfDay?
    /// "집 → 회사 · 1711번"
    var routeDescription: String?
    var alertLeadMinutes: Int?
}
