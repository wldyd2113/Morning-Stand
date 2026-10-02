import Foundation

/// 섹션 상태 → 위젯 스냅샷 / Live Activity 값. 출발 단계는 도메인 규칙(`PlanDepartureUseCase`)으로 미리 계산한다.
enum DashboardSnapshotMapper {
    private static let secondsPerMinute: TimeInterval = 60

    static func snapshot(
        weather: SectionState<WeatherSummary>,
        departures: SectionState<DepartureBoard>,
        theme: DisplayTheme,
        now: Date,
        calendar: Calendar,
        planDeparture: PlanDepartureUseCase
    ) -> DashboardSnapshot? {
        let departure = departures.value.map { board in
            self.departure(board, fetchedAt: departures.fetchedAt ?? now, now: now, planDeparture: planDeparture)
        }
        let weatherValue = weather.value.map { self.weather($0, theme: theme, now: now, calendar: calendar) }
        guard departure != nil || weatherValue != nil else { return nil }
        return DashboardSnapshot(generatedAt: now, departure: departure, weather: weatherValue)
    }

    // MARK: - 출발

    static func departure(_ board: DepartureBoard, fetchedAt: Date, now: Date, planDeparture: PlanDepartureUseCase) -> DashboardSnapshot.Departure {
        let primary = board.primary
        var arrivalAt: Date?
        var nextArrivalAt: Date?
        var statusText: String?
        switch primary.status {
        case .arriving(let minutes, let nextMinutes):
            arrivalAt = fetchedAt.addingTimeInterval(TimeInterval(minutes) * secondsPerMinute)
            nextArrivalAt = nextMinutes.map { fetchedAt.addingTimeInterval(TimeInterval($0) * secondsPerMinute) }
        case .ended:
            statusText = String(localized: "운행 종료")
        case .message(let text):
            statusText = text
        }
        return DashboardSnapshot.Departure(
            routeTitle: StandDisplayMapper.routeTitle(primary),
            stopName: primary.stopName,
            walkMinutes: board.walkMinutes,
            vehicleText: StandDisplayMapper.vehicleText(primary.kind),
            arrivalAt: arrivalAt,
            nextArrivalAt: nextArrivalAt,
            statusText: statusText,
            moments: moments(arrivalAt: arrivalAt, nextArrivalAt: nextArrivalAt, walkMinutes: board.walkMinutes, from: now, planDeparture: planDeparture)
        )
    }

    /// 지금부터 1분 간격으로 출발 단계를 계산한다. 다음 차까지 놓치면 그 시점에서 멈춘다.
    static func moments(arrivalAt: Date?, nextArrivalAt: Date?, walkMinutes: Int, from now: Date, planDeparture: PlanDepartureUseCase) -> [DashboardSnapshot.Moment] {
        guard let arrivalAt else { return [] }
        var result: [DashboardSnapshot.Moment] = []
        for minute in 0...PolicyConstants.Widget.timelineMinutes {
            let date = now.addingTimeInterval(TimeInterval(minute) * secondsPerMinute)
            let plan = planDeparture(
                arrivalMinutes: wholeMinutes(from: date, to: arrivalAt),
                nextArrivalMinutes: nextArrivalAt.map { wholeMinutes(from: date, to: $0) },
                walkMinutes: walkMinutes
            )
            result.append(DashboardSnapshot.Moment(
                date: date,
                urgency: DepartureUrgencyLevel(plan.urgency),
                minutesUntilDeparture: plan.minutesUntilDeparture,
                nextDepartureMinutes: plan.nextDepartureMinutes
            ))
            if plan.urgency == .missed && plan.nextDepartureMinutes == nil { break }
        }
        return result
    }

    private static func wholeMinutes(from start: Date, to end: Date) -> Int {
        Int((end.timeIntervalSince(start) / secondsPerMinute).rounded(.down))
    }

    // MARK: - 날씨

    static func weather(_ summary: WeatherSummary, theme: DisplayTheme, now: Date, calendar: Calendar) -> DashboardSnapshot.Weather {
        let display = StandDisplayMapper.weather(summary, theme: theme)
        let rainText = summary.rainStartHour.map { hour in
            String(localized: "\(DisplayFormatter.hourText(hour: hour, on: now, calendar: calendar))부터 비")
        }
        return DashboardSnapshot.Weather(
            temperatureText: display.temperatureText,
            conditionText: display.conditionText,
            rangeText: display.rangeText,
            symbolName: StandWeatherView.symbolName(display.symbol),
            pm10Text: display.pm10.label,
            pm25Text: display.pm25.label,
            pm10Level: DashboardSnapshot.AirLevel(summary.pm10),
            pm25Level: DashboardSnapshot.AirLevel(summary.pm25),
            rainText: rainText
        )
    }

    // MARK: - Live Activity

    /// 도착 시각을 아는 노선이 있을 때만 Live Activity 값을 만든다.
    /// 이번 차를 걸어서 못 타면 다음 차를 기준으로 카운트다운·진행 막대·시각·색을 모두 바꾼다.
    static func liveActivityContent(
        departures: SectionState<DepartureBoard>,
        now: Date,
        planDeparture: PlanDepartureUseCase
    ) -> LiveActivityContent? {
        guard case .loaded(let board, let fetchedAt) = departures else { return nil }
        let departure = departure(board, fetchedAt: fetchedAt, now: now, planDeparture: planDeparture)
        guard let arrivalAt = departure.arrivalAt, let moment = departure.moment(at: now) else { return nil }

        let useNext = moment.urgency == .missed && departure.nextArrivalAt != nil
        let targetArrival = useNext ? (departure.nextArrivalAt ?? arrivalAt) : arrivalAt
        let urgency: DepartureUrgencyLevel
        if useNext {
            // 다음 차만 따로 놓고 단계를 다시 계산한다
            let plan = planDeparture(arrivalMinutes: wholeMinutes(from: now, to: targetArrival), nextArrivalMinutes: nil, walkMinutes: board.walkMinutes)
            urgency = DepartureUrgencyLevel(plan.urgency)
        } else {
            urgency = moment.urgency
        }
        return LiveActivityContent(
            routeTitle: departure.routeTitle,
            stopName: departure.stopName,
            walkMinutes: departure.walkMinutes,
            vehicleText: departure.vehicleText,
            updatedAt: now,
            departAt: targetArrival.addingTimeInterval(-TimeInterval(board.walkMinutes) * secondsPerMinute),
            arrivalAt: targetArrival,
            isNextVehicle: useNext,
            urgency: urgency
        )
    }
}

extension DepartureUrgencyLevel {
    nonisolated init(_ urgency: DepartureUrgency) {
        switch urgency {
        case .relaxed: self = .relaxed
        case .soon: self = .soon
        case .now: self = .now
        case .missed: self = .missed
        }
    }
}

extension DashboardSnapshot.AirLevel {
    nonisolated init(_ level: AirQualityLevel) {
        switch level {
        case .good: self = .good
        case .moderate: self = .moderate
        case .bad: self = .bad
        case .veryBad: self = .veryBad
        case .unavailable: self = .unavailable
        }
    }
}
