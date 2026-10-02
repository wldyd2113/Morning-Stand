import Foundation

/// 직선거리로 도보 시간을 어림할 때 쓰는 기준값. 지도 경로를 못 받았을 때의 대체값이다.
nonisolated struct WalkingPolicy: Sendable, Equatable {
    /// 실제 길은 직선보다 길다 (골목·횡단보도)
    var detourFactor: Double
    var speedMetersPerSecond: Double
    var minimumMinutes: Int
    var maximumMinutes: Int

    static let standard = WalkingPolicy(detourFactor: 1.3, speedMetersPerSecond: 1.2, minimumMinutes: 1, maximumMinutes: 30)
}
