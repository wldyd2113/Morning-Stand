import Foundation

/// 지금 보여줄 화면.
nonisolated enum ScreenMode: Sendable, Equatable {
    /// 반접힘: 시계·날씨 / 출발 카운트다운
    case stand
    /// 펼침: 경로 비교, 루틴·설정
    case planning
    /// 접힘(커버 화면): 문 나서기 직전에 꺼내 보는 한눈 모드
    case glance

    init(posture: DevicePosture) {
        switch posture {
        case .halfOpened: self = .stand
        case .flat: self = .planning
        case .closed: self = .glance
        }
    }
}
