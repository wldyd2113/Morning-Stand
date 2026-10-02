import Foundation

/// 기기가 놓여 있는지, 손에 들려 있는지. 자세(반접힘/펼침) 판정에 창 모양과 함께 쓴다.
nonisolated enum MotionState: String, Sendable, Equatable {
    /// 협탁 등에 놓여 한동안 거의 움직이지 않음
    case resting
    /// 손에 들고 움직이는 중
    case handheld
    /// 센서가 없거나(시뮬레이터) 아직 판단 전
    case unavailable
}
