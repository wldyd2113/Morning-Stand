import Foundation

/// 지역 하나의 상태 변화.
nonisolated struct RegionPresenceChange: Sendable, Equatable {
    var region: CommuteRegion
    var presence: RegionPresence
    var date: Date
}
