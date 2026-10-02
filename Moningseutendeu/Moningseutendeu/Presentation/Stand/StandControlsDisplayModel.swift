import Foundation

/// 반접힘 아래쪽 조작판이 그리는 값: 정류장 넘기기, 출발 알림 버튼.
nonisolated struct StandControlsDisplayModel: Sendable, Equatable {
    /// 지금 보고 있는 즐겨찾기 정류장 이름. 즐겨찾기가 없으면 nil
    var stopTitle: String?
    /// "1/4". 즐겨찾기가 하나면 nil
    var stopPosition: String?
    var canSwitchStop: Bool
    var reminder: Reminder
    /// 다음 기상 알람 ("내일 오전 6:50"). 꺼져 있으면 nil
    var nextAlarmText: String?

    nonisolated enum Reminder: Sendable, Equatable {
        /// 남은 시간을 아는 차량이 없어서 예약할 수 없음
        case unavailable
        /// 예약할 수 있음 ("출발 5분 전 알림")
        case available(title: String)
        /// 예약됨 ("7:44에 알려드려요")
        case scheduled(title: String, detail: String)
    }
}
