import Foundation

/// 주변 탭 상태 → 표시 모델. 현재 시각은 인자로 받는 순수 함수라 고정 날짜로 테스트한다.
nonisolated enum NearbyDisplayMapper {
    typealias Model = NearbyDisplayModel

    /// ViewModel 상태를 그대로 옮긴 입력값.
    struct Input: Sendable {
        var location: SectionState<LocationFix>
        var stops: SectionState<[TransitStop]>
        var searchGeneration: Int
        var selectedStopID: String?
        var mapWalkMinutes: [String: SectionState<Int>]
        var arrivals: [String: SectionState<[RouteArrival]>]
        var refreshingStopIDs: Set<String>
        var favoriteStopIDs: Set<String>
        var home: Coordinate?
        var isUpdatingHome: Bool
        var isAutomationOn: Bool
        var isUpdatingAutomation: Bool
        var automationError: String?
        var isSaving: Bool
        var saveError: String?
        var now: Date
    }

    static func make(_ input: Input, calendar: Calendar, planDeparture: PlanDepartureUseCase) -> Model {
        let selectedStop = input.stops.value?.first { $0.id == input.selectedStopID }
        return Model(
            locationText: input.location.value.map(locationText),
            isLocating: input.location == .loading || input.stops == .loading,
            pins: pins(input),
            message: message(location: input.location, stops: input.stops),
            showsOpenSettings: input.location == .failed(.locationDenied),
            initialCenter: input.home ?? PolicyConstants.DefaultLocation.coordinate,
            userCoordinate: input.location.value?.coordinate,
            homeCoordinate: input.home,
            searchGeneration: input.searchGeneration,
            resultSummary: input.stops.value.flatMap { $0.isEmpty ? nil : String(localized: "주변 정류장 \($0.count)곳") },
            home: home(input),
            automation: automation(input),
            selection: selectedStop.map { selection(for: $0, input: input, calendar: calendar, planDeparture: planDeparture) }
        )
    }

    /// 지도 도보 시간이 있으면 그 값, 없으면 직선거리 어림값.
    static func walkMinutes(for stop: TransitStop, mapWalkMinutes: [String: SectionState<Int>]) -> Int {
        mapWalkMinutes[stop.id]?.value ?? stop.estimatedWalkMinutes
    }

    static func isPreciseEnough(_ fix: LocationFix) -> Bool {
        fix.isPrecise(maxAccuracyMeters: PolicyConstants.Location.nearbySearchMaxAccuracyMeters)
    }

    static func locationText(_ fix: LocationFix) -> String {
        fix.isAccuracyReduced
            ? String(localized: "대략적인 위치 기준")
            : String(localized: "현재 위치 기준 · 오차 \(Int(fix.horizontalAccuracyMeters.rounded()))m")
    }

    // MARK: - 지도 · 안내

    private static func pins(_ input: Input) -> [Model.Pin] {
        (input.stops.value ?? []).compactMap { stop in
            stop.coordinate.map { coordinate in
                Model.Pin(
                    id: stop.id,
                    name: stop.name,
                    coordinate: coordinate,
                    isSelected: stop.id == input.selectedStopID,
                    isFavorite: input.favoriteStopIDs.contains(stop.id)
                )
            }
        }
    }

    static func message(location: SectionState<LocationFix>, stops: SectionState<[TransitStop]>) -> String? {
        if case .failed(let error) = location { return error.userMessage }
        if let fix = location.value, !isPreciseEnough(fix) {
            return String(localized: "정확한 위치가 꺼져 있어 주변 정류장을 찾을 수 없어요. 설정에서 '정확한 위치'를 켜 주세요")
        }
        if case .failed(let error) = stops { return error.userMessage }
        if stops.value?.isEmpty == true { return String(localized: "반경 \(PolicyConstants.Location.nearbyRadiusMeters)m 안에 정류장이 없어요") }
        return nil
    }

    // MARK: - 집 · 자동 처리

    private static func home(_ input: Input) -> Model.Home {
        let isSet = input.home != nil
        return Model.Home(
            title: isSet
                ? String(localized: "집 위치가 설정돼 있어요. 날씨와 도보 시간을 집 기준으로 계산해요")
                : String(localized: "집에 있을 때 현재 위치를 집으로 설정하면 날씨와 도보 시간을 집 기준으로 계산해요"),
            actionTitle: isSet ? String(localized: "현재 위치로 다시 설정") : String(localized: "현재 위치를 집으로 설정"),
            isSet: isSet,
            isUpdating: input.isUpdatingHome
        )
    }

    private static func automation(_ input: Input) -> Model.Automation {
        let needsHome = input.home == nil && !input.isAutomationOn
        return Model.Automation(
            isOn: input.isAutomationOn,
            // 이미 켜져 있으면 끌 수는 있어야 한다
            isAvailable: !needsHome,
            unavailableReason: needsHome ? String(localized: "먼저 위에서 집 위치를 설정하면 켤 수 있어요") : nil,
            isUpdating: input.isUpdatingAutomation,
            detail: String(localized: "집을 나서면 출발 카운트다운을 끝내고 출근을 기록해요. 정류장 근처에 오면 도착 정보를 알려 드려요"),
            errorMessage: input.automationError
        )
    }

    // MARK: - 고른 정류장

    private static func selection(for stop: TransitStop, input: Input, calendar: Calendar, planDeparture: PlanDepartureUseCase) -> Model.Selection {
        let walkState = input.mapWalkMinutes[stop.id]
        let walk = walkMinutes(for: stop, mapWalkMinutes: input.mapWalkMinutes)
        let source: String = switch walkState {
        case .loaded: input.home == nil ? String(localized: "지도 도보 경로 · 현재 위치에서") : String(localized: "지도 도보 경로 · 집에서")
        case .loading: String(localized: "지도에서 도보 경로를 계산하는 중")
        default: String(localized: "직선거리로 어림한 시간")
        }
        var detail = [stop.id]
        if let meters = stop.distanceMeters { detail.append(DisplayFormatter.distanceText(meters: meters)) }
        let isFavorite = input.favoriteStopIDs.contains(stop.id)
        return Model.Selection(
            name: stop.name,
            detail: detail.joined(separator: " · "),
            walkMinutesText: String(localized: "\(walk)분"),
            walkSourceText: source,
            isCalculatingWalk: walkState == .loading,
            arrivals: arrivals(
                input.arrivals[stop.id] ?? .idle,
                isRefreshing: input.refreshingStopIDs.contains(stop.id),
                walkMinutes: walk,
                now: input.now,
                calendar: calendar,
                planDeparture: planDeparture
            ),
            actionTitle: isFavorite ? String(localized: "즐겨찾기 저장됨 · 도보 시간 다시 저장") : String(localized: "이 도보 시간으로 즐겨찾기에 추가"),
            isSaving: input.isSaving,
            errorMessage: input.saveError
        )
    }

    /// 도착 정보 → 행. 남은 시간이 있는 노선은 도보 시간을 빼서 "N분 뒤 출발"까지 붙인다.
    static func arrivals(
        _ state: SectionState<[RouteArrival]>,
        isRefreshing: Bool,
        walkMinutes: Int,
        now: Date,
        calendar: Calendar,
        planDeparture: PlanDepartureUseCase
    ) -> Model.Arrivals {
        switch state {
        case .idle, .loading:
            return .loading
        case .loaded(let routes, let fetchedAt), .stale(let routes, let fetchedAt, _):
            guard !routes.isEmpty else { return .message(String(localized: "지금 도착 정보가 없어요")) }
            let updated = String(localized: "\(DisplayFormatter.elapsedText(from: fetchedAt, to: now, calendar: calendar)) 기준")
            let rows = routes.map { arrivalRow($0, walkMinutes: walkMinutes, planDeparture: planDeparture) }
            return .rows(rows, updatedText: updated, isRefreshing: isRefreshing)
        case .failed(let error):
            return .message(error.userMessage)
        }
    }

    static func arrivalRow(_ route: RouteArrival, walkMinutes: Int, planDeparture: PlanDepartureUseCase) -> Model.ArrivalRow {
        let base = StandDisplayMapper.row(route)
        var row = Model.ArrivalRow(
            id: route.id,
            title: StandDisplayMapper.routeTitle(route),
            subtitle: route.kind == .bus ? (route.destination ?? "") : "",
            etaText: base.etaText,
            nextText: base.nextText
        )
        if case .arriving(let minutes, let next) = route.status {
            let plan = planDeparture(arrivalMinutes: minutes, nextArrivalMinutes: next, walkMinutes: walkMinutes)
            row.urgency = plan.urgency
            row.departureText = departureText(plan)
        }
        return row
    }

    static func departureText(_ plan: DeparturePlan) -> String {
        switch plan.urgency {
        case .relaxed, .soon: String(localized: "\(plan.minutesUntilDeparture)분 뒤 출발")
        case .now: String(localized: "지금 출발")
        case .missed:
            plan.nextDepartureMinutes.map { String(localized: "이번 차 놓침 · 다음 차 \($0)분 뒤 출발") } ?? String(localized: "이번 차 놓침")
        }
    }
}
