import Foundation

/// 지도 도보 경로로 걸리는 시간(초)을 구한다. 구현(MapKit)은 Platform에 있다.
nonisolated protocol WalkingRouteService: Sendable {
    func walkingSeconds(from start: Coordinate, to end: Coordinate) async throws -> TimeInterval
}
