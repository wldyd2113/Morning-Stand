import Foundation

/// 첫 번째 즐겨찾기 정류장(역)의 도착 정보. 버스는 서울 버스, 지하철은 서울 지하철 실시간 API.
nonisolated struct DefaultDepartureRepository: DepartureRepository {
    let requester: PublicAPIRequester
    let fetcher: CachedFetcher
    let settings: any UserSettingsRepository
    let dateProvider: any DateProvider
    var calendar: Calendar = .seoul

    func fetchDepartureBoard() async throws -> Timestamped<DepartureBoard> {
        guard let favorite = settings.favoriteStops().first else { throw AppError.notConfigured }
        let arrivals = try await ArrivalLoader(requester: requester, fetcher: fetcher, dateProvider: dateProvider, calendar: calendar)
            .arrivals(stopID: favorite.id, kind: favorite.kind, stopName: favorite.name)
        return Timestamped(
            value: Self.board(arrivals: arrivals.value, favorite: favorite),
            fetchedAt: arrivals.fetchedAt,
            freshness: arrivals.freshness
        )
    }

    func arrivals(at stop: TransitStop) async throws -> Timestamped<[RouteArrival]> {
        var result = try await ArrivalLoader(requester: requester, fetcher: fetcher, dateProvider: dateProvider, calendar: calendar)
            .arrivals(stopID: stop.id, kind: stop.kind, stopName: stop.name)
        result.value.sort { Self.sortMinutes($0.status) < Self.sortMinutes($1.status) }
        return result
    }

    /// 알림 받을 노선 중 첫 번째를 히어로 카드로, 나머지는 도착이 빠른 순으로 "다른 노선"에 둔다.
    static func board(arrivals: [RouteArrival], favorite: FavoriteStop) -> DepartureBoard {
        let primary = favorite.trackedRoutes.lazy.compactMap { tracked in arrivals.first { $0.key == tracked } }.first
            ?? arrivals.first
            ?? RouteArrival(
                routeName: favorite.trackedRoutes.first ?? favorite.name,
                kind: favorite.kind,
                stopName: favorite.name,
                status: .message(String(localized: "도착 정보 없음"))
            )
        let others = arrivals
            .filter { $0.id != primary.id }
            .sorted { Self.sortMinutes($0.status) < Self.sortMinutes($1.status) }
        return DepartureBoard(walkMinutes: favorite.walkMinutes, primary: primary, others: others)
    }

    /// 도착이 빠른 순으로 정렬할 때의 키. 남은 시간을 모르는 노선은 뒤로 보낸다
    static func sortMinutes(_ status: ArrivalStatus) -> Int {
        switch status {
        case .arriving(let minutes, _): minutes
        case .message: Int.max - 1
        case .ended: Int.max
        }
    }
}

/// 버스·지하철 도착 정보를 캐시를 거쳐 받는다. 지하철은 시간 보정 때문에 원본 DTO를 캐시하고 읽을 때 변환한다.
nonisolated struct ArrivalLoader: Sendable {
    let requester: PublicAPIRequester
    let fetcher: CachedFetcher
    let dateProvider: any DateProvider
    let calendar: Calendar

    func arrivals(stopID: String, kind: TransportKind, stopName: String) async throws -> Timestamped<[RouteArrival]> {
        let requester = requester
        switch kind {
        case .bus:
            let result = try await fetcher.fetch(key: "bus.arrivals.\(stopID)", api: .seoulBus, ttl: PolicyConstants.CacheTTL.busArrival) {
                try await requester.seoulBus(
                    path: APIConstants.SeoulBus.arrivalsByStopPath,
                    query: [APIConstants.SeoulBus.arsId: stopID],
                    as: SeoulBusArrivalDTO.self
                )
            }
            let arrivals = result.value.compactMap { SeoulBusMapper.arrival($0, stopName: stopName) }
            return Timestamped(value: arrivals, fetchedAt: result.fetchedAt, freshness: result.freshness)
        case .subway:
            let result = try await fetcher.fetch(key: "subway.arrivals.\(stopID)", api: .seoulSubway, ttl: PolicyConstants.CacheTTL.subwayArrival) {
                try await requester.subwayArrivals(stationName: stopID)
            }
            let arrivals = SeoulSubwayMapper.arrivals(result.value, stationName: stopName, now: dateProvider.now, calendar: calendar)
            return Timestamped(value: arrivals, fetchedAt: result.fetchedAt, freshness: result.freshness)
        }
    }
}
