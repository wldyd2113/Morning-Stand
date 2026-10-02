import Foundation

/// 한 번 받은 현재 위치와 수평 오차.
nonisolated struct LocationFix: Sendable, Equatable {
    var coordinate: Coordinate
    /// 수평 오차(m). 대략적 위치(reduced accuracy)면 수 km가 된다
    var horizontalAccuracyMeters: Double
    /// 사용자가 "정확한 위치"를 껐는지
    var isAccuracyReduced: Bool
}
