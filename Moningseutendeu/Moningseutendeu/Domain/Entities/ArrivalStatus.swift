import Foundation

/// 한 노선의 도착 상태.
nonisolated enum ArrivalStatus: Sendable, Equatable {
    /// `minutes`분 뒤 도착. 다음 차량 정보가 있으면 `nextMinutes`.
    case arriving(minutes: Int, nextMinutes: Int?)
    /// 운행 종료. 막차·첫차 시각을 알면 함께 둔다.
    case ended(lastDeparture: TimeOfDay?, firstDeparture: TimeOfDay?)
    /// 남은 시간을 알 수 없고 상태 문구만 있음 ("전역 도착", "출발대기"). 출발 시각을 계산하지 않는다.
    case message(String)
}
