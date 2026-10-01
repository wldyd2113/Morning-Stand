import Foundation

/// 출발까지 남은 시간에 따른 단계.
nonisolated enum DepartureUrgency: Sendable, Equatable, CaseIterable {
    /// 출발까지 여유 있음
    case relaxed
    /// 곧 출발해야 함
    case soon
    /// 지금 바로 출발해야 함
    case now
    /// 걸어서는 이번 차량을 못 탐
    case missed
}
