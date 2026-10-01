import Foundation

/// 경로·루틴 → 플래닝 화면 표시 모델.
nonisolated enum PlanningDisplayMapper {
    typealias Model = PlanningDisplayModel

    static func make(
        routes: SectionState<[CommuteRoute]>,
        selectedRouteID: String?,
        routines: [Weekday: RoutineSetting],
        selectedWeekday: Weekday,
        now: Date,
        calendar: Calendar
    ) -> Model {
        let content: Model.Content
        switch routes {
        case .idle, .loading: content = .loading
        case .loaded(let value, _), .stale(let value, _, _): content = value.isEmpty ? .empty : .loaded
        case .failed(let error): content = .failed(message: error.userMessage)
        }
        let routeList = routes.value ?? []
        let selectedRoute = routeList.first { $0.id == selectedRouteID } ?? routeList.first

        return Model(
            content: content,
            routes: routeList.map { routeRow($0, isSelected: $0.id == selectedRoute?.id, calendar: calendar) },
            detail: selectedRoute.map { detail($0, calendar: calendar) },
            legend: legend(),
            weekdays: Weekday.displayOrder.map { weekday in
                Model.DayChip(
                    weekday: weekday,
                    label: shortName(weekday, calendar: calendar),
                    isSelected: weekday == selectedWeekday,
                    isEnabled: routines[weekday]?.isEnabled ?? false
                )
            },
            routineSummary: routineSummary(routines),
            routine: routine(routines[selectedWeekday], weekday: selectedWeekday, now: now, calendar: calendar)
        )
    }

    static func routeRow(_ route: CommuteRoute, isSelected: Bool, calendar: Calendar) -> Model.RouteRow {
        Model.RouteRow(
            id: route.id,
            name: route.name,
            schedule: scheduleText(route, calendar: calendar),
            bestText: route.fastestMinutes.map { String(localized: "\($0)분") } ?? "—",
            isSelected: isSelected
        )
    }

    static func detail(_ route: CommuteRoute, calendar: Calendar) -> Model.Detail {
        let fastest = route.fastestMinutes
        let area = [route.origin, route.destination].filter { !$0.isEmpty }.joined(separator: " → ")
        return Model.Detail(
            title: route.name,
            subtitle: [area, scheduleText(route, calendar: calendar)].filter { !$0.isEmpty }.joined(separator: " · "),
            options: route.options.map { option(for: $0, departure: route.departure, fastestMinutes: fastest) }
        )
    }

    static func option(for option: RouteOption, departure: TimeOfDay, fastestMinutes: Int?) -> Model.Option {
        let total = option.totalMinutes
        let isFastest = total == fastestMinutes
        let arrival = String(localized: "\(departure.adding(minutes: total).text) 도착")
        let tag = isFastest ? String(localized: "가장 빠름") : option.note
        return Model.Option(
            id: option.id,
            totalText: "\(total)",
            isFastest: isFastest,
            title: option.title,
            tag: tag,
            arrivalText: arrival,
            segments: option.segments.enumerated().map { index, segment in
                Model.Segment(id: index, kind: segment.kind, minutes: segment.minutes, caption: caption(segment), compactCaption: "\(segment.minutes)")
            },
            accessibilityLabel: String(localized: "\(option.title), \(total)분 소요, \(tag), \(arrival)")
        )
    }

    /// 짧은 구간은 분만, 긴 구간은 "1711번 22"처럼 이름까지 보여준다.
    static func caption(_ segment: RouteSegment) -> String {
        guard segment.minutes >= PolicyConstants.Planning.segmentLabelMinimumMinutes else { return "\(segment.minutes)" }
        let label = segment.label ?? kindName(segment.kind)
        return "\(label) \(segment.minutes)"
    }

    static func kindName(_ kind: RouteSegment.Kind) -> String {
        switch kind {
        case .walk: String(localized: "도보")
        case .wait: String(localized: "대기")
        case .bus: String(localized: "버스")
        case .subway: String(localized: "지하철")
        case .transfer: String(localized: "환승")
        }
    }

    static func legend() -> [Model.LegendItem] {
        RouteSegment.Kind.allCases.map { Model.LegendItem(kind: $0, name: kindName($0)) }
    }

    /// "평일 08:10 출발", "화·목 18:40 출발"
    static func scheduleText(_ route: CommuteRoute, calendar: Calendar) -> String {
        String(localized: "\(weekdaysText(route.weekdays, calendar: calendar)) \(route.departure.text) 출발")
    }

    /// 월~금 → "평일", 토·일 → "주말", 7일 → "매일", 그 외는 "화·목"
    static func weekdaysText(_ weekdays: [Weekday], calendar: Calendar) -> String {
        let set = Set(weekdays)
        let weekend = Set(Weekday.allCases.filter(\.isWeekend))
        let workdays = Set(Weekday.allCases).subtracting(weekend)
        if set.count == Weekday.allCases.count { return String(localized: "매일") }
        if set == workdays { return String(localized: "평일") }
        if set == weekend { return String(localized: "주말") }
        if set.isEmpty { return String(localized: "요일 미정") }
        return Weekday.displayOrder.filter(set.contains).map { shortName($0, calendar: calendar) }.joined(separator: "·")
    }

    static func shortName(_ weekday: Weekday, calendar: Calendar) -> String {
        calendar.veryShortStandaloneWeekdaySymbols[weekday.rawValue - 1]
    }

    static func routineSummary(_ routines: [Weekday: RoutineSetting]) -> String {
        let enabled = routines.values.filter(\.isEnabled)
        let weekend = enabled.filter { $0.weekday.isWeekend }.count
        let weekdays = enabled.count - weekend
        return String(localized: "평일 \(weekdays)일 · 주말 \(weekend)일")
    }

    static func routine(_ setting: RoutineSetting?, weekday: Weekday, now: Date, calendar: Calendar) -> Model.Routine {
        let dayName = calendar.standaloneWeekdaySymbols[weekday.rawValue - 1]
        let none = String(localized: "없음")
        return Model.Routine(
            toggleTitle: String(localized: "\(dayName) 루틴 사용"),
            isEnabled: setting?.isEnabled ?? false,
            timeText: setting?.departure.map { DisplayFormatter.meridiemTimeText($0, on: now, calendar: calendar) } ?? "—",
            routeText: setting?.routeDescription ?? none,
            alertText: setting?.alertLeadMinutes.map { String(localized: "출발 \($0)분 전") } ?? none
        )
    }
}
