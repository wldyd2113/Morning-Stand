import Foundation

/// 지역 이벤트로 출근 기록을 만들고 채운다. 저장은 하지 않는 순수 계산이다.
nonisolated struct RecordCommuteUseCase: Sendable {
    var policy: CommuteRecordPolicy = .standard

    /// 집을 나섰을 때. 아직 정류장에 닿지 않은 기록이 있으면(잠깐 나갔다 온 경우) 그 기록의 출발 시각을 바꾼다.
    func leftHome(at date: Date, favorite: FavoriteStop, plan: DeparturePlan?, openRecord: CommuteRecord?, makeID: () -> UUID = UUID.init) -> CommuteRecord {
        var record = openRecord ?? CommuteRecord(
            id: makeID(),
            leftHomeAt: date,
            reachedStopAt: nil,
            stopName: favorite.name,
            kind: favorite.kind,
            routeName: nil,
            boardedAt: nil,
            missedPlannedVehicle: false
        )
        record.leftHomeAt = date
        record.missedPlannedVehicle = plan?.urgency == .missed
        return record
    }

    /// 정류장에 도착했을 때. 그때 가장 먼저 오는 차량(알림 노선 우선)을 탄 것으로 본다.
    func reachedStop(_ record: CommuteRecord, at date: Date, board: DepartureBoard?) -> CommuteRecord {
        var record = record
        record.reachedStopAt = date
        if let (routeName, minutes) = Self.firstVehicle(in: board) {
            record.routeName = routeName
            record.boardedAt = date.addingTimeInterval(.minutes(minutes))
        }
        return record
    }

    /// "지금 출발"을 직접 눌렀을 때. 도보 시간 뒤 정류장에 닿는다고 보고, 그때 탈 수 있는 첫 차량을 탄 것으로 본다.
    /// 진행 중인 기록(지역 감시가 이미 만든 기록)이 있으면 새로 만들지 않고 그 기록을 채운다.
    func leftHomeManually(at date: Date, favorite: FavoriteStop, board: DepartureBoard?, plan: DeparturePlan?, openRecord: CommuteRecord? = nil, makeID: () -> UUID = UUID.init) -> CommuteRecord {
        var record = leftHome(at: date, favorite: favorite, plan: plan, openRecord: openRecord, makeID: makeID)
        let walkMinutes = board?.walkMinutes ?? favorite.walkMinutes
        record.reachedStopAt = date.addingTimeInterval(.minutes(walkMinutes))
        if let (routeName, minutes) = Self.firstCatchableVehicle(in: board, walkMinutes: walkMinutes) {
            record.routeName = routeName
            record.boardedAt = date.addingTimeInterval(.minutes(minutes))
        }
        return record
    }

    /// 정류장 도착 이벤트를 붙일 진행 중 기록. 집을 나선 지 너무 오래됐으면 다른 외출로 본다.
    func openRecord(in records: [CommuteRecord], at date: Date) -> CommuteRecord? {
        let limit = TimeInterval.minutes(policy.maximumWalkToStopMinutes)
        return records
            .filter { $0.reachedStopAt == nil && $0.leftHomeAt <= date && date.timeIntervalSince($0.leftHomeAt) <= limit }
            .max { $0.leftHomeAt < $1.leftHomeAt }
    }

    /// 걸어가는 동안 떠나지 않는 첫 차량 (각 노선의 이번 차·다음 차 중). 알림 노선을 먼저 본다.
    private static func firstCatchableVehicle(in board: DepartureBoard?, walkMinutes: Int) -> (String, Int)? {
        guard let board else { return nil }
        func catchable(_ arrival: RouteArrival) -> (String, Int)? {
            guard case .arriving(let minutes, let next) = arrival.status else { return nil }
            let candidates = [minutes, next].compactMap { $0 }.filter { $0 >= walkMinutes }
            return candidates.min().map { (arrival.routeName, $0) }
        }
        return catchable(board.primary) ?? board.others.compactMap(catchable).min { $0.1 < $1.1 }
    }

    private static func firstVehicle(in board: DepartureBoard?) -> (String, Int)? {
        guard let board else { return nil }
        if case .arriving(let minutes, _) = board.primary.status {
            return (board.primary.routeName, max(minutes, 0))
        }
        return board.others
            .compactMap { arrival -> (String, Int)? in
                guard case .arriving(let minutes, _) = arrival.status else { return nil }
                return (arrival.routeName, max(minutes, 0))
            }
            .min { $0.1 < $1.1 }
    }
}
