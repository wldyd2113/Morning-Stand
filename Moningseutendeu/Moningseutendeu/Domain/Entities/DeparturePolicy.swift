import Foundation

/// 출발 단계 기준값. Domain 안에 두고 UseCase에 주입한다 (앱 상수에 의존하지 않기 위해).
nonisolated struct DeparturePolicy: Sendable, Equatable {
    /// 출발까지 이 시간(분) 이상 남으면 "여유"
    var relaxedThresholdMinutes: Int
    /// 출발까지 이 시간(분) 이상 남으면 "곧 출발", 미만이면 "지금 출발"
    var soonThresholdMinutes: Int

    static let standard = DeparturePolicy(relaxedThresholdMinutes: 10, soonThresholdMinutes: 3)
}
