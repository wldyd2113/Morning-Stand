import Foundation

/// 스탠드 화면 아래 패널에 쓰는 도착 정보 묶음.
nonisolated struct DepartureBoard: Sendable, Equatable {
    /// 집에서 정류장까지 걸리는 시간(분). 출발 시각 계산에 쓴다.
    var walkMinutes: Int
    /// 기본 경로의 노선 (히어로 카드)
    var primary: RouteArrival
    /// "다른 노선" 목록
    var others: [RouteArrival]
}
