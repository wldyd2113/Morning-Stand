import Foundation

/// 서울 버스 응답 → 도메인. 도착 메시지("3분12초후[2번째 전]", "곧 도착", "운행종료", "출발대기")를 해석한다.
nonisolated enum SeoulBusMapper {
    typealias Constants = APIConstants.SeoulBus

    enum ParsedMessage: Sendable, Equatable {
        case seconds(Int)
        case soon
        case ended
        case other(String)
    }

    static func parse(_ message: String?) -> ParsedMessage {
        guard let message, !message.isEmpty else { return .other("") }
        if message.contains(Constants.soonMessage) { return .soon }
        if message.contains(Constants.endedMessage) { return .ended }
        let pattern = /(?:(\d+)\s*분)?\s*(?:(\d+)\s*초)?\s*후/
        if let match = message.firstMatch(of: pattern), match.output.1 != nil || match.output.2 != nil {
            let minutes = match.output.1.flatMap { Int($0) } ?? 0
            let seconds = match.output.2.flatMap { Int($0) } ?? 0
            return .seconds(minutes * 60 + seconds)
        }
        return .other(message)
    }

    /// 메시지를 먼저 보고, 남은 시간이 있는 메시지일 때만 초 단위 `traTime`(더 정확함)을 쓴다.
    /// 운행종료인데 `traTime1`이 5처럼 엉뚱한 값으로 오는 경우가 있어서 메시지가 우선이다 (2026-10-01 실제 응답).
    static func seconds(travelTime: String?, message: String?) -> ParsedMessage {
        let parsed = parse(message)
        guard case .seconds = parsed, let seconds = travelTime.flatMap(Int.init), seconds > 0 else { return parsed }
        return .seconds(seconds)
    }

    static func arrival(_ dto: SeoulBusArrivalDTO, stopName: String) -> RouteArrival? {
        guard let route = dto.rtNm, !route.isEmpty else { return nil }
        let first = seconds(travelTime: dto.traTime1, message: dto.arrmsg1)
        let next: Int? = switch seconds(travelTime: dto.traTime2, message: dto.arrmsg2) {
        case .seconds(let value): value / 60
        case .soon: 0
        case .ended, .other: nil
        }
        let status: ArrivalStatus = switch first {
        case .seconds(let value): .arriving(minutes: value / 60, nextMinutes: next)
        case .soon: .arriving(minutes: 0, nextMinutes: next)
        case .ended: .ended(lastDeparture: nil, firstDeparture: nil)
        case .other(let text): .message(text)
        }
        return RouteArrival(
            routeName: route,
            kind: .bus,
            stopName: dto.stNm ?? stopName,
            destination: dto.adirection.map { $0 + String(localized: " 방면") },
            status: status
        )
    }

    /// `tmX`는 경도, `tmY`는 위도 (이름과 달리 WGS84)
    static func stop(_ dto: SeoulBusStationDTO) -> TransitStop? {
        // 정류소 번호가 "0"인 곳(경기 정류소 등)은 도착 조회를 할 수 없어서 뺀다
        guard let arsId = dto.arsId, arsId != "0", let name = dto.stNm else { return nil }
        var coordinate: Coordinate?
        if let longitude = dto.tmX.flatMap(Double.init), let latitude = dto.tmY.flatMap(Double.init) {
            coordinate = Coordinate(latitude: latitude, longitude: longitude)
        }
        return TransitStop(
            id: arsId,
            name: name,
            kind: .bus,
            direction: "",
            distanceMeters: nil,
            estimatedWalkMinutes: PolicyConstants.Walking.defaultMinutes,
            routeNames: [],
            coordinate: coordinate
        )
    }
}
