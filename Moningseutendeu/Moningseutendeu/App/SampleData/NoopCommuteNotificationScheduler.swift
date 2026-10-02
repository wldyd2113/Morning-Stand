import Foundation

/// Preview·테스트용. 아무것도 하지 않는다.
nonisolated struct NoopCommuteNotificationScheduler: CommuteNotificationScheduling {
    func scheduleDepartureReminder(at date: Date, title: String, body: String) async -> Bool { true }
    func cancelDepartureReminder() async {}

    func requestAuthorization() async -> Bool { true }
    func notifyNearStop(title: String, body: String) async {}
}
