import Foundation

/// 정류장·역 검색. 버스는 서울 버스 정류소 이름 검색, 지하철은 역 이름으로 실시간 도착을 조회해 확인한다.
nonisolated struct DefaultTransitStopRepository: TransitStopRepository {
    let requester: PublicAPIRequester
    let fetcher: CachedFetcher
    let dateProvider: any DateProvider
    var calendar: Calendar = .seoul

    func searchStops(query: String, kind: TransportKind) async throws -> [TransitStop] {
        let keyword = query.trimmingCharacters(in: .whitespaces)
        guard !keyword.isEmpty else { return [] }
        let requester = requester
        switch kind {
        case .bus:
            let result = try await fetcher.fetch(key: "bus.stations.\(keyword)", api: .seoulBus, ttl: PolicyConstants.CacheTTL.stationList) {
                try await requester.seoulBus(
                    path: APIConstants.SeoulBus.stationByNamePath,
                    query: [APIConstants.SeoulBus.stationQuery: keyword],
                    as: SeoulBusStationDTO.self
                )
            }
            return result.value.compactMap(SeoulBusMapper.stop)
        case .subway:
            let stationName = SeoulSubwayMapper.normalizedStationName(keyword)
            let arrivals = try await loader.arrivals(stopID: stationName, kind: .subway, stopName: stationName)
            guard !arrivals.value.isEmpty else { return [] }
            return [SeoulSubwayMapper.stop(stationName: stationName, arrivals: arrivals.value)]
        }
    }

    func routeNames(for stop: TransitStop) async throws -> [String] {
        guard stop.routeNames.isEmpty else { return stop.routeNames }
        let arrivals = try await loader.arrivals(stopID: stop.id, kind: stop.kind, stopName: stop.name)
        return arrivals.value.map(\.key)
    }

    private var loader: ArrivalLoader {
        ArrivalLoader(requester: requester, fetcher: fetcher, dateProvider: dateProvider, calendar: calendar)
    }
}
