import Foundation

/// 출근 시간대. 폴링 간격, Live Activity 표시, 출근 기록·정류장 알림 여부를 이 기준으로 정한다.
nonisolated struct CommuteHourPolicy: Sendable, Equatable {
    /// 이 시각(시) 이상
    var startHour: Int
    /// 이 시각(시) 미만
    var endHour: Int

    static let standard = CommuteHourPolicy(startHour: 6, endHour: 10)

    func contains(_ date: Date, calendar: Calendar) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour >= startHour && hour < endHour
    }
}
