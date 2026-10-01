import Foundation

/// 측정소 목록 샘플 (실제 응답에서 일부를 옮겼다).
nonisolated struct SampleAirQualityStationRepository: AirQualityStationRepository {
    func stationNames() async throws -> [String] {
        ["중구", "종로구", "용산구", "은평구", "서대문구", "마포구", "강남구", "송파구"]
    }
}
