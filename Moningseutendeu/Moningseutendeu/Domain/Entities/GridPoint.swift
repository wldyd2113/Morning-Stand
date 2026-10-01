import Foundation

/// 기상청 단기예보 격자 좌표.
nonisolated struct GridPoint: Sendable, Equatable, Hashable {
    var nx: Int
    var ny: Int
}
