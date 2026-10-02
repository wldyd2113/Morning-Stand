import Foundation

/// 공공 API 연동 전까지 쓰는 도착 정보 샘플 저장소. 값은 디자인 시안과 같다.
nonisolated struct SampleDepartureRepository: DepartureRepository {
    let scenario: StandScenario
    let dateProvider: any DateProvider
    let clock: any Clock<Duration>
    var calendar: Calendar = .seoul

    private static let stop = "연신내역"
    private static let walkMinutes = 5

    static let others = [
        RouteArrival(routeName: "3호선", kind: .subway, stopName: stop, destination: "오금행", status: .arriving(minutes: 8, nextMinutes: 14)),
        RouteArrival(routeName: "7212", kind: .bus, stopName: stop, status: .arriving(minutes: 15, nextMinutes: 28)),
        RouteArrival(routeName: "720", kind: .bus, stopName: stop, status: .arriving(minutes: 19, nextMinutes: 33)),
    ]

    static func board(primaryStatus: ArrivalStatus, others: [RouteArrival] = others) -> DepartureBoard {
        DepartureBoard(
            walkMinutes: walkMinutes,
            primary: RouteArrival(routeName: "1711", kind: .bus, stopName: stop, status: primaryStatus),
            others: others
        )
    }

    func fetchDepartureBoard() async throws -> Timestamped<DepartureBoard> {
        let now = dateProvider.now
        switch scenario {
        case .loading:
            try await clock.sleep(for: .seconds(60 * 60))
            throw AppError.timeout
        case .relaxed:
            return Timestamped(value: Self.board(primaryStatus: .arriving(minutes: 23, nextMinutes: 38)), fetchedAt: seconds(-12, from: now))
        case .soon, .weatherStale:
            return Timestamped(value: Self.board(primaryStatus: .arriving(minutes: 12, nextMinutes: 24)), fetchedAt: seconds(-12, from: now))
        case .now:
            return Timestamped(value: Self.board(primaryStatus: .arriving(minutes: 6, nextMinutes: 19)), fetchedAt: seconds(-12, from: now))
        case .missed:
            return Timestamped(value: Self.board(primaryStatus: .arriving(minutes: 3, nextMinutes: 19)), fetchedAt: seconds(-12, from: now))
        case .offline:
            return Timestamped(
                value: Self.board(primaryStatus: .arriving(minutes: 12, nextMinutes: 24)),
                fetchedAt: seconds(-24 * 60, from: now),
                freshness: .cached(.offline)
            )
        case .ended:
            let others = [
                RouteArrival(routeName: "N37", kind: .bus, stopName: Self.stop, destination: "심야버스", status: .arriving(minutes: 24, nextMinutes: 49)),
                RouteArrival(routeName: "7212", kind: .bus, stopName: Self.stop, status: .ended(lastDeparture: nil, firstDeparture: TimeOfDay(hour: 4, minute: 30))),
                RouteArrival(routeName: "3호선", kind: .subway, stopName: Self.stop, status: .ended(lastDeparture: nil, firstDeparture: TimeOfDay(hour: 5, minute: 32))),
            ]
            let status = ArrivalStatus.ended(lastDeparture: TimeOfDay(hour: 23, minute: 52), firstDeparture: TimeOfDay(hour: 4, minute: 40))
            return Timestamped(value: Self.board(primaryStatus: status, others: others), fetchedAt: seconds(-12, from: now))
        }
    }

    /// 지도에서 고른 정류장. 시안의 노선을 그 정류장 이름으로 돌려준다.
    func arrivals(at stop: TransitStop) async throws -> Timestamped<[RouteArrival]> {
        let routes = [RouteArrival(routeName: "1711", kind: .bus, stopName: stop.name, destination: "불광역 방면", status: .arriving(minutes: 4, nextMinutes: 17))]
            + Self.others.filter { $0.kind == stop.kind }.map { route in
                var route = route
                route.stopName = stop.name
                return route
            }
        return Timestamped(value: routes, fetchedAt: seconds(-12, from: dateProvider.now))
    }

    private func seconds(_ value: Int, from date: Date) -> Date {
        calendar.date(byAdding: .second, value: value, to: date) ?? date
    }
}
