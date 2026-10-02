import Foundation

/// 출근 기록과 통계 → 표시 모델. 순수 함수라 고정 날짜로 테스트한다.
nonisolated enum CommuteHistoryDisplayMapper {
    private static let minutesPerHour = 60

    static func make(records: SectionState<[CommuteRecord]>, statistics: CommuteStatistics, actionError: String?, calendar: Calendar) -> CommuteHistoryDisplayModel {
        let list = records.value ?? []
        var message: String?
        if case .failed(let error) = records {
            message = error.userMessage
        } else if records.value?.isEmpty == true {
            message = String(localized: "아직 출근 기록이 없어요. 주변 탭에서 자동 처리를 켜거나 '지금 출발'을 눌러 기록해 보세요")
        }

        let points = statistics.dailyDepartures.map { departure in
            let minute = departure.leftHomeAt.hour * minutesPerHour + departure.leftHomeAt.minute
            let time = DisplayFormatter.meridiemTimeText(departure.leftHomeAt, on: departure.day, calendar: calendar)
            let missedText = departure.missed ? String(localized: " · 놓침") : ""
            return CommuteHistoryDisplayModel.DeparturePoint(
                day: departure.day,
                minuteOfDay: minute,
                missed: departure.missed,
                accessibilityText: "\(DisplayFormatter.shortDateText(for: departure.day, calendar: calendar)) \(String(localized: "\(time) 출발"))\(missedText)"
            )
        }
        let padding = PolicyConstants.History.chartAxisPaddingMinutes
        let axis = (points.map(\.minuteOfDay).min() ?? 0) - padding ... (points.map(\.minuteOfDay).max() ?? 0) + padding

        return CommuteHistoryDisplayModel(
            periodText: String(localized: "최근 \(PolicyConstants.History.lookbackDays)일"),
            tiles: tiles(statistics),
            weekdayBars: statistics.weekdayAverages.map { average in
                CommuteHistoryDisplayModel.WeekdayBar(
                    label: weekdayLabel(average.weekday, calendar: calendar),
                    averageMinutes: average.averageMinutes,
                    valueText: String(localized: "평균 \(Int(average.averageMinutes.rounded()))분 · \(average.count)회")
                )
            },
            departurePoints: points,
            departureAxisMinutes: axis,
            rows: list.reversed().map { row($0, calendar: calendar) },
            isLoading: records == .loading,
            message: message,
            actionError: actionError
        )
    }

    /// y축 눈금 "7:40"
    static func axisTimeText(minuteOfDay: Int) -> String {
        let time = TimeOfDay(hour: 0, minute: 0).adding(minutes: minuteOfDay)
        return "\(time.hour):\(String(format: "%02d", time.minute))"
    }

    static func weekdayLabel(_ weekday: Weekday, calendar: Calendar) -> String {
        let symbols = calendar.shortWeekdaySymbols
        let index = weekday.rawValue - 1
        return symbols.indices.contains(index) ? symbols[index] : ""
    }

    private static func tiles(_ statistics: CommuteStatistics) -> [CommuteHistoryDisplayModel.Tile] {
        let fastest = statistics.fastestRoute
        return [
            .init(
                id: "total",
                label: String(localized: "출근"),
                value: String(localized: "\(statistics.totalCount)회"),
                detail: averageDepartureText(statistics.dailyDepartures).map { String(localized: "평균 \($0) 출발") }
            ),
            .init(
                id: "missed",
                label: String(localized: "놓친 횟수"),
                value: String(localized: "\(statistics.missedCount)회"),
                detail: statistics.totalCount > 0 ? String(localized: "\(statistics.totalCount)회 중") : nil
            ),
            .init(
                id: "fastest",
                label: String(localized: "가장 빠른 노선"),
                value: fastest.map { routeTitle($0.routeName) } ?? "—",
                detail: fastest.map { String(localized: "평균 \(Int($0.averageMinutes.rounded()))분 · \($0.count)회") }
                    ?? String(localized: "같은 노선 기록이 더 필요해요")
            ),
        ]
    }

    /// 집을 나선 평균 시각 "7:41"
    static func averageDepartureText(_ departures: [CommuteStatistics.DailyDeparture]) -> String? {
        guard !departures.isEmpty else { return nil }
        let total = departures.reduce(0) { $0 + $1.leftHomeAt.hour * minutesPerHour + $1.leftHomeAt.minute }
        return axisTimeText(minuteOfDay: Int((Double(total) / Double(departures.count)).rounded()))
    }

    private static func row(_ record: CommuteRecord, calendar: Calendar) -> CommuteHistoryDisplayModel.Row {
        let time = DisplayFormatter.meridiemTimeText(TimeOfDay(date: record.leftHomeAt, calendar: calendar), on: record.leftHomeAt, calendar: calendar)
        var parts = [String(localized: "\(time) 출발")]
        if let route = record.routeName {
            parts.append(record.kind == .bus ? routeTitle(route) : route)
        }
        if record.reachedStopAt == nil {
            parts.append(String(localized: "정류장 도착 전"))
        }
        return CommuteHistoryDisplayModel.Row(
            id: record.id,
            dateText: DisplayFormatter.shortDateText(for: record.leftHomeAt, calendar: calendar),
            detail: parts.joined(separator: " · "),
            minutesText: record.doorToBoardMinutes.map { String(localized: "\($0)분") } ?? "—",
            missed: record.missedPlannedVehicle
        )
    }

    /// 버스 번호에는 "번"을 붙인다 ("1711" → "1711번"). 지하철 노선("3호선")은 그대로 둔다.
    private static func routeTitle(_ name: String) -> String {
        let isSubwayLine = name.hasSuffix(String(localized: "호선"))
        return name.first?.isNumber == true && !isSubwayLine ? String(localized: "\(name)번") : name
    }
}
