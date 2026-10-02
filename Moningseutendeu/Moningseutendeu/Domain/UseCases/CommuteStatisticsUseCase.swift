import Foundation

/// 출근 기록 → 요일별 평균 소요 시간, 놓친 횟수, 노선별 평균, 가장 빠른 노선.
/// 소요 시간은 집을 나선 뒤 차량에 탈 때까지(분)이며, 탑승 시각을 모르는 기록은 평균에서 뺀다.
nonisolated struct CommuteStatisticsUseCase: Sendable {
    var policy: CommuteRecordPolicy = .standard

    func callAsFunction(_ records: [CommuteRecord], calendar: Calendar) -> CommuteStatistics {
        guard !records.isEmpty else { return .empty }

        let timed = records.compactMap { record in record.doorToBoardMinutes.map { (record, Double($0)) } }

        let byWeekday = Dictionary(grouping: timed) { Weekday(rawValue: calendar.component(.weekday, from: $0.0.leftHomeAt)) ?? .monday }
        let weekdayAverages = Weekday.displayOrder.compactMap { weekday -> CommuteStatistics.WeekdayAverage? in
            guard let items = byWeekday[weekday], !items.isEmpty else { return nil }
            return CommuteStatistics.WeekdayAverage(weekday: weekday, averageMinutes: Self.average(items.map(\.1)), count: items.count)
        }

        let byRoute = Dictionary(grouping: timed.filter { $0.0.routeName != nil }) { $0.0.routeName ?? "" }
        let routeAverages = byRoute
            .map { CommuteStatistics.RouteAverage(routeName: $0.key, averageMinutes: Self.average($0.value.map(\.1)), count: $0.value.count) }
            .sorted { ($0.averageMinutes, $0.routeName) < ($1.averageMinutes, $1.routeName) }

        let dailyDepartures = records
            .sorted { $0.leftHomeAt < $1.leftHomeAt }
            .map { record in
                CommuteStatistics.DailyDeparture(
                    day: calendar.startOfDay(for: record.leftHomeAt),
                    leftHomeAt: TimeOfDay(date: record.leftHomeAt, calendar: calendar),
                    missed: record.missedPlannedVehicle
                )
            }

        return CommuteStatistics(
            totalCount: records.count,
            missedCount: records.count { $0.missedPlannedVehicle },
            weekdayAverages: weekdayAverages,
            routeAverages: routeAverages,
            dailyDepartures: dailyDepartures,
            fastestRoute: routeAverages.first { $0.count >= policy.minimumRouteSamples }
        )
    }

    private static func average(_ values: [Double]) -> Double {
        values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }
}
