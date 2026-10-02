import Foundation

/// 기상 알람 예약. 구현(AlarmKit)은 Platform에 있다.
nonisolated protocol WakeAlarmScheduling: Sendable {
    /// 알람 권한을 요청한다. 허용됐는지 돌려준다
    func requestAuthorization() async -> Bool
    /// 기존 알람을 지우고 설정대로 다시 건다. 꺼져 있으면 지우기만 한다
    func apply(_ setting: WakeAlarmSetting) async throws
}
