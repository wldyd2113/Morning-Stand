import Foundation

/// 지금 보여줄 화면.
nonisolated enum ScreenMode: Sendable, Equatable {
    /// 반접힘: 시계·날씨 / 출발 카운트다운
    case stand
    /// 펼침: 경로 비교, 루틴·설정
    case planning

    init(posture: DevicePosture) {
        switch posture {
        case .halfOpened: self = .stand
        case .flat, .closed: self = .planning
        }
    }
}
