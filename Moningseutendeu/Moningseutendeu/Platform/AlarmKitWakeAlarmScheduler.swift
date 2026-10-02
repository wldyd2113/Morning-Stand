import AlarmKit
import Foundation
import SwiftUI

/// AlarmKit으로 기상 알람을 건다. 무음 모드·집중 모드에서도 울리고,
/// 알람 화면의 "출발 보기" 버튼을 누르면 앱이 열려 오늘의 출발 카운트다운을 보여준다.
nonisolated struct AlarmKitWakeAlarmScheduler: WakeAlarmScheduling {
    /// 알람 화면에 함께 넘기는 값 (지금은 쓰지 않지만 AlarmAttributes가 요구한다)
    nonisolated struct Metadata: AlarmMetadata {}

    /// 알람 화면 색과 "출발 보기" 버튼 심볼. 디자인 토큰은 MainActor라 조립할 때 넘겨받는다
    let tintColor: Color
    let departureSymbol: String

    func requestAuthorization() async -> Bool {
        let manager = AlarmManager.shared
        switch manager.authorizationState {
        case .authorized: return true
        case .denied: return false
        case .notDetermined: return (try? await manager.requestAuthorization()) == .authorized
        @unknown default: return false
        }
    }

    func apply(_ setting: WakeAlarmSetting) async throws {
        let manager = AlarmManager.shared
        // 앱이 건 알람은 기상 알람 하나뿐이라 모두 지우고 다시 건다
        for alarm in (try? manager.alarms) ?? [] {
            try? manager.cancel(id: alarm.id)
        }
        guard setting.isEnabled, !setting.weekdays.isEmpty else { return }

        let alert = AlarmPresentation.Alert(
            title: "출근 준비할 시간이에요",
            secondaryButton: AlarmButton(text: "출발 보기", textColor: .black, systemImageName: departureSymbol),
            secondaryButtonBehavior: .custom
        )
        let attributes = AlarmAttributes<Metadata>(presentation: AlarmPresentation(alert: alert), tintColor: tintColor)
        let schedule = Alarm.Schedule.relative(.init(
            time: .init(hour: setting.time.hour, minute: setting.time.minute),
            repeats: .weekly(setting.weekdays.map(\.localeWeekday))
        ))
        _ = try await manager.schedule(
            id: UUID(),
            configuration: .alarm(schedule: schedule, attributes: attributes, secondaryIntent: OpenDepartureScreenIntent())
        )
    }
}

private extension Weekday {
    nonisolated var localeWeekday: Locale.Weekday {
        switch self {
        case .sunday: .sunday
        case .monday: .monday
        case .tuesday: .tuesday
        case .wednesday: .wednesday
        case .thursday: .thursday
        case .friday: .friday
        case .saturday: .saturday
        }
    }
}
