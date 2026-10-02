import Foundation

/// 출근 기록 통계. `CommuteStatisticsUseCase`가 만든다.
nonisolated struct CommuteStatistics: Sendable, Equatable {
    nonisolated struct WeekdayAverage: Sendable, Equatable {
        var weekday: Weekday
        /// 집 → 탑승 평균(분)
        var averageMinutes: Double
        var count: Int
    }

    nonisolated struct RouteAverage: Sendable, Equatable {
        var routeName: String
        var averageMinutes: Double
        var count: Int
    }

    nonisolated struct DailyDeparture: Sendable, Equatable {
        var day: Date
        /// 집을 나선 시각
        var leftHomeAt: TimeOfDay
        var missed: Bool
    }

    var totalCount: Int
    var missedCount: Int
    /// 월요일부터, 기록이 있는 요일만
    var weekdayAverages: [WeekdayAverage]
    /// 평균이 짧은 순
    var routeAverages: [RouteAverage]
    /// 날짜 오름차순
    var dailyDepartures: [DailyDeparture]

    /// 평균 소요 시간이 가장 짧은 노선 (기록이 기준 횟수 이상인 노선 중)
    var fastestRoute: RouteAverage?

    static let empty = CommuteStatistics(totalCount: 0, missedCount: 0, weekdayAverages: [], routeAverages: [], dailyDepartures: [], fastestRoute: nil)
}
