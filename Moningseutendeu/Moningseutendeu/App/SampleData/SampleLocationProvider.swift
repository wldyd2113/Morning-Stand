import Foundation

/// Preview·UI 테스트용 고정 위치 (연신내역 부근).
nonisolated struct SampleLocationProvider: LocationProvider {
    static let coordinate = Coordinate(latitude: 37.6190, longitude: 126.9210)
    static let accuracyMeters: Double = 20

    func currentLocation() async throws -> LocationFix {
        LocationFix(coordinate: Self.coordinate, horizontalAccuracyMeters: Self.accuracyMeters, isAccuracyReduced: false)
    }
}

/// Preview·UI 테스트용 도보 경로. 직선거리 × 우회 계수 ÷ 속도로 돌려준다.
nonisolated struct SampleWalkingRouteService: WalkingRouteService {
    func walkingSeconds(from start: Coordinate, to end: Coordinate) async throws -> TimeInterval {
        let policy = WalkingPolicy.standard
        return GeoDistance.meters(from: start, to: end) * policy.detourFactor / policy.speedMetersPerSecond
    }
}

/// Preview·UI 테스트용 지역 감시. 이벤트를 내보내지 않는다.
nonisolated struct NoopCommuteRegionMonitor: CommuteRegionMonitoring {
    func presenceChanges() async -> AsyncStream<RegionPresenceChange> {
        AsyncStream { $0.finish() }
    }

    func monitor(home: Coordinate?, stop: Coordinate?) async {}

    func requestAlwaysAuthorization() async -> Bool { true }
}
