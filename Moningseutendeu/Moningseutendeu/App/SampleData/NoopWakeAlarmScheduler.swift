import Foundation

/// Preview·테스트용. 아무것도 하지 않는다.
nonisolated struct NoopWakeAlarmScheduler: WakeAlarmScheduling {
    func requestAuthorization() async -> Bool { true }
    func apply(_ setting: WakeAlarmSetting) async throws {}
}
