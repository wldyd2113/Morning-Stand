#if DEBUG
import Foundation
import OSLog

/// 디버그 전용 확인 도구: `-scheduleTestAlarm`으로 실행하면 1분 뒤 기상 알람을 실제 AlarmKit 경로로 건다.
/// 알람 권한·예약·울림·"출발 보기" 흐름을 화면 조작 없이 확인하기 위한 것이라 Release 빌드에는 들어가지 않는다.
enum WakeAlarmSmokeTest {
    static let launchArgument = "-scheduleTestAlarm"

    static func runIfRequested(dependencies: AppDependencies, arguments: [String] = ProcessInfo.processInfo.arguments) async {
        guard arguments.contains(launchArgument) else { return }
        let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: AppConstants.Logging.alarmCategory)
        let scheduler = dependencies.wakeAlarmScheduler
        let calendar = dependencies.calendar
        let now = dependencies.dateProvider.now

        let isAuthorized = await scheduler.requestAuthorization()
        logger.info("[알람 확인] 권한: \(isAuthorized ? "허용" : "거부", privacy: .public)")
        guard isAuthorized else { return }

        let fireAt = now.addingTimeInterval(60)
        guard let weekday = Weekday(rawValue: calendar.component(.weekday, from: fireAt)) else { return }
        let setting = WakeAlarmSetting(isEnabled: true, time: TimeOfDay(date: fireAt, calendar: calendar), weekdays: [weekday])
        do {
            try await scheduler.apply(setting)
            dependencies.settingsRepository.setWakeAlarm(setting)
            logger.info("[알람 확인] 예약 완료: \(setting.time.text, privacy: .public) (\(String(describing: weekday), privacy: .public))")
        } catch {
            logger.error("[알람 확인] 예약 실패: \(String(describing: error), privacy: .public)")
        }
    }
}
#endif
