import Foundation

/// 정류장 검색 샘플. 이름에 검색어가 들어간 정류장만 돌려준다.
nonisolated struct SampleTransitStopRepository: TransitStopRepository {
    static let stops: [TransitStop] = [
        TransitStop(id: "12-345", name: "연신내역", kind: .bus, direction: "불광역 방면", distanceMeters: 380, estimatedWalkMinutes: 6, routeNames: ["1711", "7212", "720"]),
        TransitStop(id: "12-346", name: "연신내역", kind: .bus, direction: "구파발역 방면", distanceMeters: 420, estimatedWalkMinutes: 7, routeNames: ["1711", "7211", "701"]),
        TransitStop(id: "12-512", name: "연신내로데오거리", kind: .bus, direction: "갈현동 방면", distanceMeters: 560, estimatedWalkMinutes: 8, routeNames: ["7022", "9701"]),
        TransitStop(id: "321", name: "연신내역", kind: .subway, direction: "3호선", distanceMeters: 350, estimatedWalkMinutes: 5, routeNames: ["3호선 오금행", "3호선 대화행"]),
        TransitStop(id: "614", name: "연신내역", kind: .subway, direction: "6호선", distanceMeters: 400, estimatedWalkMinutes: 6, routeNames: ["6호선 응암순환"]),
    ]

    /// Preview용 즐겨찾기 (시안의 연신내역 정류장)
    static let favorites: [FavoriteStop] = stops.prefix(1).map { stop in
        FavoriteStop(id: stop.id, kind: stop.kind, name: stop.name, direction: stop.direction, walkMinutes: stop.estimatedWalkMinutes, trackedRoutes: Array(stop.routeNames.prefix(1)))
    } + stops.filter { $0.kind == .subway }.prefix(1).map { stop in
        FavoriteStop(id: stop.id, kind: stop.kind, name: stop.name, direction: stop.direction, walkMinutes: stop.estimatedWalkMinutes, trackedRoutes: Array(stop.routeNames.prefix(1)))
    }

    func searchStops(query: String, kind: TransportKind) async throws -> [TransitStop] {
        let keyword = query.trimmingCharacters(in: .whitespaces)
        return Self.stops.filter { stop in
            stop.kind == kind && (keyword.isEmpty || stop.name.localizedStandardContains(keyword))
        }
    }

    func routeNames(for stop: TransitStop) async throws -> [String] {
        stop.routeNames
    }
}
