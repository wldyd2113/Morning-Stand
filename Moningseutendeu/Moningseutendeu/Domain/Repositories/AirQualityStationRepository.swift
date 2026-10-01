import Foundation

/// 미세먼지 측정소 이름 목록 저장소.
nonisolated protocol AirQualityStationRepository: Sendable {
    func stationNames() async throws -> [String]
}
