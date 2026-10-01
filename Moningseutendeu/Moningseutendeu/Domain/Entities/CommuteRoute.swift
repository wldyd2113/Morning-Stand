import Foundation

/// 즐겨찾기 경로 (예: 집 → 회사).
nonisolated struct CommuteRoute: Sendable, Equatable, Identifiable, Codable {
    var id: String
    var name: String
    /// "불광동"
    var origin: String
    /// "광화문"
    var destination: String
    var departure: TimeOfDay
    /// 이 경로로 출발하는 요일 (월요일 시작 순서)
    var weekdays: [Weekday]
    var options: [RouteOption]

    /// 가장 빠른 이동 방법의 소요 시간(분). 이동 방법이 없으면 `nil`.
    var fastestMinutes: Int? { options.map(\.totalMinutes).min() }
}
