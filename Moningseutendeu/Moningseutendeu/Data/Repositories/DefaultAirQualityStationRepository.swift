import Foundation

/// 서울 측정소 이름 목록 (시도별 실시간 측정정보에서 뽑는다. 측정소정보 서비스는 미승인).
nonisolated struct DefaultAirQualityStationRepository: AirQualityStationRepository {
    let requester: PublicAPIRequester
    let fetcher: CachedFetcher

    func stationNames() async throws -> [String] {
        typealias Keys = APIConstants.AirKorea
        let sido = PolicyConstants.AirQuality.sidoName
        let requester = requester
        let result = try await fetcher.fetch(key: "air.stations.\(sido)", api: .airKorea, ttl: PolicyConstants.CacheTTL.stationList) {
            try await requester.airMeasurements(
                path: Keys.sidoMeasurementPath,
                query: [Keys.sidoName: sido, Keys.numOfRows: "\(Keys.sidoPageSize)"]
            ).compactMap(\.stationName)
        }
        return result.value
    }
}
