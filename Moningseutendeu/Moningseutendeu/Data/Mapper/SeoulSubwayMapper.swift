import Foundation

/// 서울 지하철 실시간 도착 → 노선·방향별 도착 정보.
///
/// - 남은 시간 = `barvlDt − (now − recptnDt)`, 0 미만이면 0 (CLAUDE.md 주의사항 4)
/// - `barvlDt`가 0이면: 진입·도착(arvlCd 0, 1)이고 최근 기록이면 "곧 도착", 출발(2)이면 버리고, 나머지는 문구만 보여준다
/// - 같은 열차가 중복으로 오고 오래된 "도착" 기록이 남아 있어서 걸러낸다
nonisolated enum SeoulSubwayMapper {
    typealias Constants = APIConstants.SeoulSubway

    static func arrivals(_ dtos: [SeoulSubwayArrivalDTO], stationName: String, now: Date, calendar: Calendar) -> [RouteArrival] {
        var order: [String] = []
        var groups: [String: [SeoulSubwayArrivalDTO]] = [:]
        for dto in dtos where isUsable(dto, now: now, calendar: calendar) {
            guard let key = trackingKey(dto) else { continue }
            if groups[key] == nil { order.append(key) }
            groups[key, default: []].append(dto)
        }
        return order.compactMap { key in
            guard let trains = groups[key]?.sorted(by: { ($0.ordkey ?? "") < ($1.ordkey ?? "") }), let first = trains.first else { return nil }
            let next = trains.dropFirst().first.flatMap { remainingSeconds($0, now: now, calendar: calendar) }
            return RouteArrival(
                routeName: lineName(first),
                kind: .subway,
                stopName: stationName,
                destination: direction(first),
                status: status(first, nextSeconds: next, now: now, calendar: calendar),
                trackingKey: key
            )
        }
    }

    /// 역 하나 → 검색 결과 정류장
    static func stop(stationName: String, arrivals: [RouteArrival]) -> TransitStop {
        let lines = arrivals.map(\.routeName).reduce(into: [String]()) { result, line in
            if !result.contains(line) { result.append(line) }
        }
        return TransitStop(
            id: stationName,
            name: stationName + Constants.stationSuffix,
            kind: .subway,
            direction: lines.joined(separator: " · "),
            distanceMeters: nil,
            estimatedWalkMinutes: PolicyConstants.Walking.defaultMinutes,
            routeNames: arrivals.map(\.key)
        )
    }

    /// "연신내역" → "연신내" (API는 "역"을 붙이지 않는다)
    static func normalizedStationName(_ query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasSuffix(Constants.stationSuffix), trimmed.count > Constants.stationSuffix.count else { return trimmed }
        return String(trimmed.dropLast(Constants.stationSuffix.count))
    }

    static func trackingKey(_ dto: SeoulSubwayArrivalDTO) -> String? {
        guard dto.subwayId != nil else { return nil }
        return [lineName(dto), direction(dto)].compactMap { $0 }.joined(separator: " ")
    }

    static func lineName(_ dto: SeoulSubwayArrivalDTO) -> String {
        guard let id = dto.subwayId else { return "" }
        return Constants.lineNames[id] ?? id
    }

    /// "구파발행 - 구파발방면" → "구파발방면". 없으면 상행/하행
    static func direction(_ dto: SeoulSubwayArrivalDTO) -> String? {
        if let line = dto.trainLineNm, let range = line.range(of: Constants.lineDirectionSeparator) {
            return String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        return dto.updnLine
    }

    /// 보정한 남은 초. `barvlDt`가 없거나 0이면 nil
    static func remainingSeconds(_ dto: SeoulSubwayArrivalDTO, now: Date, calendar: Calendar) -> Int? {
        guard let seconds = dto.barvlDt.flatMap(Int.init), seconds > 0 else { return nil }
        guard let received = KSTDateParser.dateTime(dto.recptnDt, calendar: calendar) else { return seconds }
        let elapsed = Int(now.timeIntervalSince(received))
        return max(seconds - max(elapsed, 0), 0)
    }

    static func status(_ dto: SeoulSubwayArrivalDTO, nextSeconds: Int?, now: Date, calendar: Calendar) -> ArrivalStatus {
        let nextMinutes = nextSeconds.map { $0 / 60 }
        if let seconds = remainingSeconds(dto, now: now, calendar: calendar) {
            return .arriving(minutes: seconds / 60, nextMinutes: nextMinutes)
        }
        if let code = dto.arvlCd, Constants.arrivalCodes.contains(code) {
            return .arriving(minutes: 0, nextMinutes: nextMinutes)
        }
        return .message(dto.arvlMsg2 ?? "")
    }

    /// 이미 떠난 열차, 오래된 "도착" 기록은 버린다
    private static func isUsable(_ dto: SeoulSubwayArrivalDTO, now: Date, calendar: Calendar) -> Bool {
        if dto.arvlCd == Constants.departedCode { return false }
        guard remainingSeconds(dto, now: now, calendar: calendar) == nil,
              let code = dto.arvlCd, Constants.arrivalCodes.contains(code),
              let received = KSTDateParser.dateTime(dto.recptnDt, calendar: calendar) else { return true }
        return now.timeIntervalSince(received) <= PolicyConstants.Subway.staleArrivalRecordSeconds
    }
}
