import Foundation

/// 섹션 상태 → 스탠드 화면 표시 모델. 시각은 인자로 받아서 결과가 항상 같게 한다.
nonisolated enum StandDisplayMapper {
    typealias Model = StandDisplayModel

    static func make(
        weather: SectionState<WeatherSummary>,
        departures: SectionState<DepartureBoard>,
        theme: DisplayTheme,
        now: Date,
        calendar: Calendar,
        planDeparture: PlanDepartureUseCase = PlanDepartureUseCase()
    ) -> Model {
        Model(
            theme: theme,
            dateText: DisplayFormatter.dateText(for: now, calendar: calendar),
            weather: weatherPanel(weather, theme: theme),
            banner: banner(weather: weather, departures: departures, now: now, calendar: calendar),
            hero: hero(departures, calendar: calendar, planDeparture: planDeparture),
            otherRoutes: otherRoutes(departures, calendar: calendar),
            footer: footer(weather: weather, departures: departures)
        )
    }

    // MARK: - 시계

    static func clock(at date: Date, calendar: Calendar) -> Model.Clock {
        let time = TimeOfDay(date: date, calendar: calendar)
        let parts = time.text.split(separator: ":").map(String.init)
        return Model.Clock(
            hour: parts.first ?? "",
            minute: parts.last ?? "",
            accessibilityLabel: DisplayFormatter.meridiemTimeText(time, on: date, calendar: calendar)
        )
    }

    // MARK: - 날씨

    static func weatherPanel(_ state: SectionState<WeatherSummary>, theme: DisplayTheme) -> Model.WeatherPanel {
        switch state {
        case .idle, .loading:
            .placeholder
        case .loaded(let summary, _):
            .content(weather(summary, theme: theme), isDimmed: false)
        case .stale(let summary, _, _):
            .content(weather(summary, theme: theme), isDimmed: true)
        case .failed:
            .unavailable(message: String(localized: "날씨 정보 없음"))
        }
    }

    static func weather(_ summary: WeatherSummary, theme: DisplayTheme) -> Model.Weather {
        let condition = conditionText(summary.condition)
        let range = String(localized: "최고 \(summary.highCelsius)° · 최저 \(summary.lowCelsius)°")
        let pm10 = Model.AirQualityChip(label: String(localized: "미세 \(airQualityText(summary.pm10))"), level: summary.pm10)
        let pm25 = Model.AirQualityChip(label: String(localized: "초미세 \(airQualityText(summary.pm25))"), level: summary.pm25)
        return Model.Weather(
            symbol: symbol(summary.condition, isNight: theme == .night),
            temperatureText: "\(summary.temperatureCelsius)°",
            conditionText: condition,
            rangeText: range,
            pm10: pm10,
            pm25: pm25,
            accessibilityLabel: String(localized: "현재 \(summary.temperatureCelsius)도, \(condition). \(range). \(pm10.label), \(pm25.label)")
        )
    }

    static func symbol(_ condition: WeatherCondition, isNight: Bool) -> Model.WeatherSymbol {
        switch condition {
        case .clear: isNight ? .moon : .sun
        case .partlyCloudy: isNight ? .cloudMoon : .cloudSun
        case .cloudy: .cloud
        case .rain: .rain
        case .snow: .snow
        }
    }

    static func conditionText(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear: String(localized: "맑음")
        case .partlyCloudy: String(localized: "구름 조금")
        case .cloudy: String(localized: "흐림")
        case .rain: String(localized: "비")
        case .snow: String(localized: "눈")
        }
    }

    static func airQualityText(_ level: AirQualityLevel) -> String {
        switch level {
        case .good: String(localized: "좋음")
        case .moderate: String(localized: "보통")
        case .bad: String(localized: "나쁨")
        case .veryBad: String(localized: "매우나쁨")
        case .unavailable: String(localized: "정보 없음")
        }
    }

    // MARK: - 배너

    /// 우선순위: 로딩 → 오프라인 → 날씨 지연 → 날씨 실패 → 비 예보
    static func banner(
        weather: SectionState<WeatherSummary>,
        departures: SectionState<DepartureBoard>,
        now: Date,
        calendar: Calendar
    ) -> Model.Banner {
        if case .loading = weather { return .placeholder }
        if case .idle = weather { return .placeholder }

        if isOffline(weather) || isOffline(departures) {
            return .notice(Model.Notice(
                style: .offline,
                badge: String(localized: "오프라인"),
                message: String(localized: "인터넷에 연결되지 않았어요. 날씨와 도착 정보가 멈춰 있어요.")
            ))
        }

        switch weather {
        case .stale(_, let fetchedAt, _):
            let elapsed = DisplayFormatter.elapsedText(from: fetchedAt, to: now, calendar: calendar)
            let departuresAreLive: Bool
            if case .loaded = departures { departuresAreLive = true } else { departuresAreLive = false }
            return .notice(Model.Notice(
                style: .stale,
                badge: String(localized: "마지막 정보 · \(elapsed)"),
                message: departuresAreLive
                    ? String(localized: "날씨를 갱신하지 못했어요. 도착 정보는 실시간이에요.")
                    : String(localized: "날씨를 갱신하지 못했어요.")
            ))
        case .failed(let error):
            return .notice(Model.Notice(style: .offline, badge: String(localized: "날씨"), message: error.userMessage))
        case .loaded(let summary, _):
            guard let rainHour = summary.rainStartHour else { return .none }
            let hourText = DisplayFormatter.hourText(hour: rainHour, on: now, calendar: calendar)
            return .rain(message: String(localized: "\(hourText)부터 비 · 우산 챙기세요"))
        case .idle, .loading:
            return .placeholder
        }
    }

    private static func isOffline<Value>(_ state: SectionState<Value>) -> Bool {
        switch state {
        case .stale(_, _, .offline), .failed(.offline): true
        default: false
        }
    }

    // MARK: - 히어로

    static func hero(_ state: SectionState<DepartureBoard>, calendar: Calendar, planDeparture: PlanDepartureUseCase = PlanDepartureUseCase()) -> Model.Hero {
        switch state {
        case .idle, .loading:
            return .placeholder
        case .loaded(let board, _), .stale(let board, _, .refreshFailed):
            return hero(for: board, planDeparture: planDeparture)
        case .stale(_, let fetchedAt, .offline):
            let time = TimeOfDay(date: fetchedAt, calendar: calendar).text
            return .notice(offlineHero(title: String(localized: "\(time) 이후 정보를 받지 못했어요")))
        case .failed(.offline):
            return .notice(offlineHero(title: String(localized: "도착 정보를 받지 못했어요")))
        case .failed(.notConfigured):
            return .notice(Model.NoticeHero(
                style: .info,
                badge: String(localized: "설정 필요"),
                headline: String(localized: "정류장 없음"),
                title: String(localized: "즐겨찾기 정류장을 추가해 주세요"),
                detail: String(localized: "펼친 화면 › 설정 › 정류장 추가")
            ))
        case .failed(let error):
            return .notice(Model.NoticeHero(
                style: .offline,
                badge: String(localized: "오류"),
                headline: String(localized: "정보 없음"),
                title: error.userMessage,
                detail: String(localized: "잠시 후 다시 불러올게요")
            ))
        }
    }

    private static func offlineHero(title: String) -> Model.NoticeHero {
        Model.NoticeHero(
            style: .offline,
            badge: String(localized: "오프라인"),
            headline: String(localized: "연결 없음"),
            title: title,
            detail: String(localized: "자동으로 다시 연결하는 중")
        )
    }

    static func hero(for board: DepartureBoard, planDeparture: PlanDepartureUseCase = PlanDepartureUseCase()) -> Model.Hero {
        let primary = board.primary
        let routeTitle = routeTitle(primary)
        switch primary.status {
        case .ended(let last, let first):
            var parts: [String] = []
            if let last { parts.append(String(localized: "막차 \(last.text) 출발함")) }
            if let first { parts.append(String(localized: "첫차 \(first.text)")) }
            return .notice(Model.NoticeHero(
                style: .ended,
                badge: String(localized: "운행 종료"),
                headline: String(localized: "막차 끝"),
                title: routeTitle,
                detail: parts.joined(separator: " · ")
            ))
        case .message(let text):
            return .notice(Model.NoticeHero(
                style: .info,
                badge: String(localized: "실시간"),
                headline: text.isEmpty ? String(localized: "정보 없음") : text,
                title: routeTitle,
                detail: String(localized: "남은 시간을 알 수 없어 출발 시각을 계산하지 않았어요")
            ))
        case .arriving(let minutes, let nextMinutes):
            let plan = planDeparture(arrivalMinutes: minutes, nextArrivalMinutes: nextMinutes, walkMinutes: board.walkMinutes)
            return .departure(departureHero(plan: plan, arrivalMinutes: minutes, board: board, routeTitle: routeTitle))
        }
    }

    private static func departureHero(plan: DeparturePlan, arrivalMinutes: Int, board: DepartureBoard, routeTitle: String) -> Model.DepartureHero {
        let vehicle = vehicleText(board.primary.kind)
        let walk = board.walkMinutes
        let arrivalText = arrivalMinutes <= 0 ? String(localized: "\(vehicle) 곧 도착") : String(localized: "\(vehicle) \(arrivalMinutes)분 후 도착")
        let arrivalDetail = String(localized: "\(arrivalText) · 정류장까지 도보 \(walk)분")

        switch plan.urgency {
        case .relaxed, .soon:
            let minutes = plan.minutesUntilDeparture
            return Model.DepartureHero(
                urgency: plan.urgency,
                badge: plan.urgency == .relaxed ? String(localized: "여유") : String(localized: "곧 출발"),
                headline: "\(minutes)",
                isNumericHeadline: true,
                unitLines: [String(localized: "분 뒤"), String(localized: "출발")],
                routeTitle: routeTitle,
                detail: arrivalDetail,
                accessibilityLabel: String(localized: "\(routeTitle), \(minutes)분 뒤 출발. \(arrivalDetail)")
            )
        case .now:
            return Model.DepartureHero(
                urgency: .now,
                badge: String(localized: "지금 출발"),
                headline: String(localized: "지금"),
                isNumericHeadline: false,
                unitLines: [String(localized: "출발"), String(localized: "하세요")],
                routeTitle: routeTitle,
                detail: arrivalDetail,
                accessibilityLabel: String(localized: "\(routeTitle), 지금 출발하세요. \(arrivalDetail)")
            )
        case .missed:
            let nextLine = plan.nextDepartureMinutes.map { String(localized: "\($0)분 뒤") } ?? String(localized: "정보 없음")
            let detail = String(localized: "이번 \(arrivalText) · 도보 \(walk)분이라 어려워요")
            return Model.DepartureHero(
                urgency: .missed,
                badge: String(localized: "놓침"),
                headline: String(localized: "놓침"),
                isNumericHeadline: false,
                unitLines: [String(localized: "다음 차"), nextLine],
                routeTitle: routeTitle,
                detail: detail,
                accessibilityLabel: String(localized: "\(routeTitle) 이번 차는 놓쳤어요. 다음 차 \(nextLine) 출발. \(detail)")
            )
        }
    }

    /// 버스는 "1711번", 지하철은 "3호선 구파발방면"
    static func routeTitle(_ route: RouteArrival) -> String {
        switch route.kind {
        case .bus: String(localized: "\(route.routeName)번")
        case .subway: [route.routeName, route.destination].compactMap { $0 }.joined(separator: " ")
        }
    }

    static func vehicleText(_ kind: TransportKind) -> String {
        switch kind {
        case .bus: String(localized: "버스")
        case .subway: String(localized: "열차")
        }
    }

    // MARK: - 다른 노선

    static func otherRoutes(_ state: SectionState<DepartureBoard>, calendar: Calendar) -> Model.OtherRoutes {
        switch state {
        case .idle, .loading:
            return .placeholder
        case .loaded(let board, _):
            return .rows(board.others.map { row($0) }, isDimmed: false)
        case .stale(let board, _, .refreshFailed):
            return .rows(board.others.map { row($0) }, isDimmed: true)
        case .stale(let board, let fetchedAt, .offline):
            let time = TimeOfDay(date: fetchedAt, calendar: calendar).text
            let rows = board.others.map { route in
                var row = row(route)
                row.etaText = "—"
                row.nextText = String(localized: "\(time) 기준")
                return row
            }
            return .rows(rows, isDimmed: true)
        case .failed(let error):
            return .unavailable(message: error.userMessage)
        }
    }

    static func row(_ route: RouteArrival) -> Model.RouteRow {
        // 모든 노선이 같은 정류장이라 방면이 있으면 방면만 보여준다 (좁은 세로 화면에서 잘리지 않게)
        let subtitle = route.destination ?? route.stopName
        let eta: String
        let next: String
        switch route.status {
        case .arriving(let minutes, let nextMinutes):
            eta = minutes <= 0 ? String(localized: "곧 도착") : String(localized: "\(minutes)분")
            next = nextMinutes.map { String(localized: "다음 \($0)분") } ?? ""
        case .ended(_, let first):
            eta = String(localized: "종료")
            next = first.map { String(localized: "첫차 \($0.text)") } ?? ""
        case .message(let text):
            eta = text
            next = ""
        }
        return Model.RouteRow(id: route.id, title: route.routeName, subtitle: subtitle, etaText: eta, nextText: next)
    }

    // MARK: - 갱신 시각

    static func footer(weather: SectionState<WeatherSummary>, departures: SectionState<DepartureBoard>) -> Model.Footer {
        switch departures {
        case .idle, .loading:
            return .loading
        case .loaded(let board, let fetchedAt):
            if case .loaded = weather { return .updated(at: fetchedAt, scope: nil) }
            return .updated(at: fetchedAt, scope: vehicleScopeText(board.primary.kind))
        case .stale(_, let fetchedAt, _):
            return .lastUpdated(at: fetchedAt)
        case .failed:
            return .unavailable
        }
    }

    private static func vehicleScopeText(_ kind: TransportKind) -> String {
        switch kind {
        case .bus: String(localized: "버스")
        case .subway: String(localized: "지하철")
        }
    }

    /// "12초 전 갱신", "버스 12초 전 갱신", "마지막 갱신 07:18 · 24분 전"
    static func footerText(_ footer: Model.Footer, at now: Date, calendar: Calendar) -> String {
        switch footer {
        case .loading:
            return String(localized: "불러오는 중")
        case .updated(let date, let scope):
            let elapsed = DisplayFormatter.elapsedText(from: date, to: now, calendar: calendar)
            guard let scope else { return String(localized: "\(elapsed) 갱신") }
            return String(localized: "\(scope) \(elapsed) 갱신")
        case .lastUpdated(let date):
            let time = TimeOfDay(date: date, calendar: calendar).text
            let elapsed = DisplayFormatter.elapsedText(from: date, to: now, calendar: calendar)
            return String(localized: "마지막 갱신 \(time) · \(elapsed)")
        case .unavailable:
            return String(localized: "갱신 실패")
        }
    }
}
