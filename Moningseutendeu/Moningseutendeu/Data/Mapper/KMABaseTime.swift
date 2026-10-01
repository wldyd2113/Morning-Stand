import Foundation

/// 기상청 API별 요청 기준 시각(base_date, base_time) 계산.
nonisolated struct KMABaseTime: Sendable, Equatable {
    var date: String
    var time: String

    private static let hour: TimeInterval = 60 * 60

    /// 초단기실황: 매시 정각 발표, 40분 이후 조회 가능. 40분 전이면 한 시간 전 발표를 쓴다.
    static func nowcast(at now: Date, calendar: Calendar) -> KMABaseTime {
        let minute = calendar.component(.minute, from: now)
        let reference = minute < PolicyConstants.KMA.nowcastAvailableMinute ? now.addingTimeInterval(-hour) : now
        let baseHour = calendar.component(.hour, from: reference)
        return KMABaseTime(date: KSTDateParser.compactDate(reference, calendar: calendar), time: String(format: "%02d00", baseHour))
    }

    /// 단기예보: 02·05·…·23시 발표, 10분 뒤부터 조회 가능. 가장 최근 발표를 쓴다 (02:10 전이면 전날 23시).
    static func villageForecast(at now: Date, calendar: Calendar) -> KMABaseTime {
        let reference = availableReference(now)
        let currentHour = calendar.component(.hour, from: reference)
        if let baseHour = PolicyConstants.KMA.forecastBaseHours.last(where: { $0 <= currentHour }) {
            return KMABaseTime(date: KSTDateParser.compactDate(reference, calendar: calendar), time: String(format: "%02d00", baseHour))
        }
        return previousDayLastForecast(reference, calendar: calendar)
    }

    /// 오늘 최고·최저기온(TMX·TMN)이 모두 들어 있는 오늘 02시 발표. 02:10 전이면 전날 23시.
    static func dailyExtremesForecast(at now: Date, calendar: Calendar) -> KMABaseTime {
        let reference = availableReference(now)
        guard let firstHour = PolicyConstants.KMA.forecastBaseHours.first,
              calendar.component(.hour, from: reference) >= firstHour else {
            return previousDayLastForecast(reference, calendar: calendar)
        }
        return KMABaseTime(date: KSTDateParser.compactDate(reference, calendar: calendar), time: String(format: "%02d00", firstHour))
    }

    private static func availableReference(_ now: Date) -> Date {
        now.addingTimeInterval(-TimeInterval(PolicyConstants.KMA.forecastAvailableDelayMinutes) * 60)
    }

    private static func previousDayLastForecast(_ reference: Date, calendar: Calendar) -> KMABaseTime {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: reference) ?? reference
        let lastHour = PolicyConstants.KMA.forecastBaseHours.last ?? 0
        return KMABaseTime(date: KSTDateParser.compactDate(yesterday, calendar: calendar), time: String(format: "%02d00", lastHour))
    }
}
