import Foundation

/// 도보 시간(분) = 직선거리 × 우회 계수 ÷ 보행 속도. 올림하고 범위 안으로 자른다.
nonisolated struct EstimateWalkingTimeUseCase: Sendable {
    var policy: WalkingPolicy = .standard

    func callAsFunction(distanceMeters: Double) -> Int {
        let seconds = max(distanceMeters, 0) * policy.detourFactor / policy.speedMetersPerSecond
        return clamped(Int(seconds.inMinutes.rounded(.up)))
    }

    /// 지도에서 받은 예상 시간(초)을 분으로 바꾼다. 올림해서 늦지 않게 한다.
    func minutes(fromTravelSeconds seconds: TimeInterval) -> Int {
        clamped(Int(max(seconds, 0).inMinutes.rounded(.up)))
    }

    private func clamped(_ minutes: Int) -> Int {
        min(max(minutes, policy.minimumMinutes), policy.maximumMinutes)
    }
}
