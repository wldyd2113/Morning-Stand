import Foundation

/// 정류장(역)에 도착하는 노선 하나.
nonisolated struct RouteArrival: Sendable, Equatable, Identifiable {
    /// 노선 이름. 버스는 번호(`1711`), 지하철은 호선(`3호선`).
    var routeName: String
    var kind: TransportKind
    var stopName: String
    /// 행선지·방면 등 보조 설명 (`오금행`, `심야버스`)
    var destination: String?
    var status: ArrivalStatus
    /// 즐겨찾기 "알림 받을 노선"과 맞춰 볼 키. 없으면 노선 이름을 쓴다 (지하철은 "3호선 구파발방면")
    var trackingKey: String? = nil

    var key: String { trackingKey ?? routeName }
    var id: String { "\(kind)-\(key)-\(stopName)-\(destination ?? "")" }
}
