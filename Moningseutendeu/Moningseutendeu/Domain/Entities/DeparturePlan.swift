import Foundation

/// "N분 뒤 출발" 계산 결과.
nonisolated struct DeparturePlan: Sendable, Equatable {
    var urgency: DepartureUrgency
    /// 도착 예정 − 도보 시간. 놓친 경우 음수.
    var minutesUntilDeparture: Int
    /// 놓쳤을 때 다음 차량 기준 출발까지 남은 시간. 다음 차량도 못 타거나 정보가 없으면 `nil`.
    var nextDepartureMinutes: Int?
}
