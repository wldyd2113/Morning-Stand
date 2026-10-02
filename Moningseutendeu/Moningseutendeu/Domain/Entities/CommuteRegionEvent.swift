import Foundation

/// 지역 감시(집·정류장)에서 나온 출근 이벤트.
nonisolated enum CommuteRegionEvent: Sendable, Equatable {
    /// 집 범위를 벗어남
    case leftHome(at: Date)
    /// 즐겨찾기 정류장 근처에 들어옴
    case nearStop(at: Date)
}

/// 감시하는 지역 종류.
nonisolated enum CommuteRegion: String, Sendable, Equatable, CaseIterable, Codable {
    case home
    case stop
}

/// 지역 안/밖 상태.
nonisolated enum RegionPresence: String, Sendable, Equatable, Codable {
    case inside
    case outside
}
