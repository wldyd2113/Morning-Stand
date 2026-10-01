import Foundation

/// 정류장·역 검색 저장소.
nonisolated protocol TransitStopRepository: Sendable {
    func searchStops(query: String, kind: TransportKind) async throws -> [TransitStop]
    /// 정류장에 서는 노선 목록. 검색 결과에 노선이 없을 때 정류장을 고르면 부른다.
    func routeNames(for stop: TransitStop) async throws -> [String]
}
