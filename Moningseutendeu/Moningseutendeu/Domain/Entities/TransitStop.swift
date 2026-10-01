import Foundation

/// 버스 정류장 또는 지하철역.
nonisolated struct TransitStop: Sendable, Equatable, Identifiable {
    /// 정류장 번호(`12-345`) 또는 역 코드
    var id: String
    var name: String
    var kind: TransportKind
    /// "불광역 방면"
    var direction: String
    /// 현재 위치에서의 거리. 모르면 `nil`
    var distanceMeters: Int?
    /// 지도 기준 예상 도보 시간(분)
    var estimatedWalkMinutes: Int
    var routeNames: [String]
    var coordinate: Coordinate? = nil
}
