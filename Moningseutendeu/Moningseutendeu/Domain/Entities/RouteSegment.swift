import Foundation

/// 경로 한 구간 (도보, 대기, 탑승, 환승).
nonisolated struct RouteSegment: Sendable, Equatable, Codable {
    nonisolated enum Kind: String, Sendable, Equatable, CaseIterable, Codable {
        case walk
        case wait
        case bus
        case subway
        case transfer
    }

    var kind: Kind
    var minutes: Int
    /// 탑승 구간의 노선 이름 (`1711번`, `3호선`). 도보·대기·환승은 `nil`.
    var label: String?
}
