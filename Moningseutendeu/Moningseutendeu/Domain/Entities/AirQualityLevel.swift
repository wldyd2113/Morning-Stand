import Foundation

/// 에어코리아 통합 등급 (좋음 / 보통 / 나쁨 / 매우나쁨).
/// - Note: `Modules/Domain` 패키지를 만들면 그쪽으로 옮긴다.
nonisolated enum AirQualityLevel: Sendable, Equatable, CaseIterable {
    case good
    case moderate
    case bad
    case veryBad
    /// 측정 중단·결측
    case unavailable
}
