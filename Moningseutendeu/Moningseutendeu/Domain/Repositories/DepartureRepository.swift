import Foundation

/// 기본 경로와 주변 노선의 도착 정보 저장소.
nonisolated protocol DepartureRepository: Sendable {
    func fetchDepartureBoard() async throws -> Timestamped<DepartureBoard>
    /// 즐겨찾기가 아닌 정류장(지도에서 고른 핀)의 도착 정보. 도착이 빠른 순
    func arrivals(at stop: TransitStop) async throws -> Timestamped<[RouteArrival]>
}
