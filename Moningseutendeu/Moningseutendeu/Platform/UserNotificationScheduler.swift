import Foundation
import OSLog
import UserNotifications

/// 출근 관련 로컬 알림. 같은 식별자로 다시 보내면 이전 알림을 바꾼다.
nonisolated struct UserNotificationScheduler: CommuteNotificationScheduling {
    private var center: UNUserNotificationCenter { .current() }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func scheduleDepartureReminder(at date: Date, title: String, body: String) async -> Bool {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        let components = Calendar.seoul.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: AppConstants.NotificationID.departureReminder, content: content, trigger: trigger)
        do {
            try await center.add(request)
            return true
        } catch {
            Logger(subsystem: AppConstants.Logging.subsystem, category: AppConstants.Logging.locationCategory)
                .error("출발 알림 예약 실패: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func cancelDepartureReminder() async {
        center.removePendingNotificationRequests(withIdentifiers: [AppConstants.NotificationID.departureReminder])
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
