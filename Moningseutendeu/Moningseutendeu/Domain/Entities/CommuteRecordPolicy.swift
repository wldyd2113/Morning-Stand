import Foundation

/// 출근 기록·통계 기준값.
nonisolated struct CommuteRecordPolicy: Sendable, Equatable {
    /// 집을 나선 뒤 이 시간(분) 안에 정류장에 도착해야 같은 출근으로 본다
    var maximumWalkToStopMinutes: Int
    /// "가장 빠른 노선"으로 뽑으려면 이 횟수 이상 탄 기록이 있어야 한다
    var minimumRouteSamples: Int

    static let standard = CommuteRecordPolicy(maximumWalkToStopMinutes: 60, minimumRouteSamples: 2)
}
