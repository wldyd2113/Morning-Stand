import Foundation
import OSLog
import UserNotifications

/// 출근 관련 로컬 알림. 같은 식별자로 다시 보내면 이전 알림을 바꾼다.
nonisolated struct UserNotificationScheduler: CommuteNotificationScheduling {
    private var center: UNUserNotificationCenter { .current() }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func notifyNearStop(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: AppConstants.NotificationID.nearStop, content: content, trigger: nil)
        do {
            try await center.add(request)
        } catch {
            Logger(subsystem: AppConstants.Logging.subsystem, category: AppConstants.Logging.locationCategory)
                .error("정류장 근처 알림 실패: \(error.localizedDescription, privacy: .public)")
        }
    }
}
