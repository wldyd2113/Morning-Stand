import ActivityKit
import Foundation

/// 출발 카운트다운 Live Activity. 서버 푸시가 없으므로 절대 시각을 넣고 화면에서 `Text(timerInterval:)`로 줄인다.
/// ContentState는 4KB 이하로 작게 유지한다.
nonisolated struct DepartureActivityAttributes: ActivityAttributes {
    /// "1711번"
    var routeTitle: String
    var stopName: String
    var walkMinutes: Int
    /// "버스", "열차"
    var vehicleText: String

    nonisolated struct ContentState: Codable, Hashable, Sendable {
        /// 마지막으로 갱신한 시각 (진행 막대의 시작점)
        var updatedAt: Date
        /// 집에서 나가야 하는 시각 (이번 차를 놓쳤으면 다음 차 기준)
        var departAt: Date
        /// 그 차량이 정류장에 도착하는 시각
        var arrivalAt: Date
        /// 이번 차를 놓쳐서 다음 차를 보여주는 중인지
        var isNextVehicle: Bool
        /// 보여주는 차량 기준 단계 (다음 차도 놓쳤으면 missed)
        var urgency: DepartureUrgencyLevel
    }
}
