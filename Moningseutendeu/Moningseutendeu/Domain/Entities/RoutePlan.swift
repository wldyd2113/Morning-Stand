import Foundation

/// 사용자가 직접 입력한 이동 방법. 길찾기 API가 없어서 구간 시간을 사람이 넣는다.
nonisolated struct RoutePlan: Sendable, Equatable, Codable {
    /// 첫 정류장에서 기다리는 예상 시간(분)
    var waitMinutes: Int
    /// 탑승 구간. 2개 이상이면 환승
    var legs: [RouteLeg]
    /// 마지막 하차 후 목적지까지 도보(분)
    var finalWalkMinutes: Int
}

/// 탑승 구간 하나: 어느 정류장에서 어떤 노선을 몇 분 타는지.
nonisolated struct RouteLeg: Sendable, Equatable, Codable {
    /// 즐겨찾기 정류장 ID (버스 arsId, 지하철 역 이름)
    var stopID: String
    var stopName: String
    var kind: TransportKind
    /// 노선 키 (버스 "1711", 지하철 "3호선 구파발방면")
    var routeKey: String
    var rideMinutes: Int
    /// 앞 구간에서 이 정류장까지 환승 이동(분). 첫 구간은 집에서 정류장까지 도보
    var accessMinutes: Int
}
