import Foundation

/// "N분 뒤 출발 = 도착 예정 − 도보 시간"을 계산하고 단계를 나눈다.
///
/// | 출발까지 | 단계 |
/// |---|---|
/// | 10분 이상 | 여유 |
/// | 3~9분 | 곧 출발 |
/// | 0~2분 | 지금 출발 |
/// | 음수 | 놓침 → 다음 차량 기준 |
nonisolated struct PlanDepartureUseCase: Sendable {
    func callAsFunction(arrivalMinutes: Int, nextArrivalMinutes: Int?, walkMinutes: Int) -> DeparturePlan {
        let minutesUntilDeparture = arrivalMinutes - walkMinutes
        guard minutesUntilDeparture >= 0 else {
            let nextDeparture = nextArrivalMinutes.map { $0 - walkMinutes }
            return DeparturePlan(
                urgency: .missed,
                minutesUntilDeparture: minutesUntilDeparture,
                nextDepartureMinutes: nextDeparture.flatMap { $0 >= 0 ? $0 : nil }
            )
        }
        return DeparturePlan(
            urgency: Self.urgency(forMinutesUntilDeparture: minutesUntilDeparture),
            minutesUntilDeparture: minutesUntilDeparture,
            nextDepartureMinutes: nil
        )
    }

    private static func urgency(forMinutesUntilDeparture minutes: Int) -> DepartureUrgency {
        if minutes >= PolicyConstants.Departure.relaxedThresholdMinutes { return .relaxed }
        if minutes >= PolicyConstants.Departure.soonThresholdMinutes { return .soon }
        return .now
    }
}
