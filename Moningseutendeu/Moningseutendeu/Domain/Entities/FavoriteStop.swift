import Foundation

/// 사용자가 즐겨찾기한 정류장(역). 스탠드 화면은 첫 번째 즐겨찾기를 기본 경로로 쓴다.
nonisolated struct FavoriteStop: Sendable, Equatable, Codable, Identifiable {
    /// 버스는 정류소 번호(arsId), 지하철은 역 이름
    var id: String
    var kind: TransportKind
    var name: String
    var direction: String
    var walkMinutes: Int
    /// 알림·히어로 카드에 쓸 노선. 비어 있으면 가장 먼저 오는 노선을 쓴다.
    var trackedRoutes: [String]
    var coordinate: Coordinate?
}
