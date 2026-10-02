import Foundation

/// 한 번 받은 현재 위치와 수평 오차.
nonisolated struct LocationFix: Sendable, Equatable {
    var coordinate: Coordinate
    /// 수평 오차(m). 대략적 위치(reduced accuracy)면 수 km가 된다
    var horizontalAccuracyMeters: Double
    /// 사용자가 "정확한 위치"를 껐는지
    var isAccuracyReduced: Bool
}

extension LocationFix {
    /// 주변 정류장 찾기처럼 정확한 위치가 필요한 기능에 쓸 수 있는지.
    /// 대략적 위치(reduced accuracy)는 오차가 수 km라서 쓰지 않는다. 날씨·측정소에는 써도 된다.
    nonisolated func isPrecise(maxAccuracyMeters: Double) -> Bool {
        !isAccuracyReduced && horizontalAccuracyMeters <= maxAccuracyMeters
    }
}
