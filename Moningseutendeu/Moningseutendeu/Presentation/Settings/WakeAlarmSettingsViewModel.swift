import Foundation
import Observation

/// 협탁 기상 알람 설정. 저장하면 AlarmKit 알람을 다시 건다.
@MainActor @Observable
final class WakeAlarmSettingsViewModel {
    struct DayChip: Identifiable, Equatable {
        let weekday: Weekday
        let label: String
        let isSelected: Bool
        var id: Weekday { weekday }
    }

    var isEnabled: Bool
    var time: Date
    private(set) var weekdays: Set<Weekday>
    private(set) var message: String?
    private(set) var isSaving = false
    /// 마지막으로 저장한 값과 다르면 저장 버튼을 켠다
    private(set) var savedSetting: WakeAlarmSetting

    @ObservationIgnored private let settings: any UserSettingsRepository
    @ObservationIgnored private let scheduler: any WakeAlarmScheduling
    @ObservationIgnored private let dateProvider: any DateProvider
    @ObservationIgnored private let calendar: Calendar

    init(settings: any UserSettingsRepository, scheduler: any WakeAlarmScheduling, dateProvider: any DateProvider, calendar: Calendar = .seoul) {
        self.settings = settings
        self.scheduler = scheduler
        self.dateProvider = dateProvider
        self.calendar = calendar
        let setting = settings.wakeAlarm()
        savedSetting = setting
        isEnabled = setting.isEnabled
        time = setting.time.date(on: dateProvider.now, calendar: calendar)
        weekdays = Set(setting.weekdays)
    }

    var dayChips: [DayChip] {
        Weekday.displayOrder.map { weekday in
            DayChip(weekday: weekday, label: PlanningDisplayMapper.shortName(weekday, calendar: calendar), isSelected: weekdays.contains(weekday))
        }
    }

    var hasChanges: Bool { draft != savedSetting }

    /// "다음 알람: 내일 오전 6:50" 또는 꺼져 있을 때 안내
    var summary: String {
        guard let next = draft.nextOccurrence(after: dateProvider.now, calendar: calendar) else {
            return draft.isEnabled ? String(localized: "요일을 하나 이상 고르세요") : String(localized: "알람이 꺼져 있어요")
        }
        return String(localized: "다음 알람: \(WakeAlarmFormatter.text(for: next, now: dateProvider.now, calendar: calendar))")
    }

    func toggleWeekday(_ weekday: Weekday) {
        if weekdays.contains(weekday) {
            weekdays.remove(weekday)
        } else {
            weekdays.insert(weekday)
        }
    }

    func save() async {
        isSaving = true
        defer { isSaving = false }
        let setting = draft
        if setting.isEnabled, await !scheduler.requestAuthorization() {
            message = String(localized: "알람 권한이 꺼져 있어요. 설정 앱 › 모닝스탠드에서 알람을 허용해 주세요.")
            return
        }
        do {
            try await scheduler.apply(setting)
            settings.setWakeAlarm(setting)
            savedSetting = setting
            message = nil
        } catch {
            message = AppError(error).userMessage
        }
    }

    private var draft: WakeAlarmSetting {
        WakeAlarmSetting(
            isEnabled: isEnabled,
            time: TimeOfDay(date: time, calendar: calendar),
            weekdays: Weekday.displayOrder.filter(weekdays.contains)
        )
    }
}
