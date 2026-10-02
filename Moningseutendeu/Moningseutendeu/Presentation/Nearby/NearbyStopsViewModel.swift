import Foundation
import Observation

/// 주변 정류장을 찾으면 지도 화면으로 이동해 핀으로 보여주고, 핀을 고르면 그 정류장의 도착 정보와 지도 도보 시간을 불러온다.
/// 집 위치와 출근 자동 처리 설정도 이 탭에서 한다.
@MainActor @Observable
final class NearbyStopsViewModel {
    private(set) var location: SectionState<LocationFix> = .idle
    private(set) var stops: SectionState<[TransitStop]> = .idle
    private(set) var searchGeneration = 0
    /// 지도 화면이 열려 있는지. 검색에 성공하면 열고, View의 뒤로 가기로 닫힌다
    var isMapPresented = false
    private(set) var selectedStopID: String?
    /// 정류장별 지도 도보 시간(분)
    private(set) var mapWalkMinutes: [String: SectionState<Int>] = [:]
    /// 정류장별 도착 정보
    private(set) var arrivals: [String: SectionState<[RouteArrival]>] = [:]
    /// 이전 값을 보여주면서 다시 받는 중인 정류장
    private(set) var refreshingStopIDs: Set<String> = []
    private(set) var favoriteStopIDs: Set<String>
    private(set) var home: Coordinate?
    private(set) var isUpdatingHome = false
    private(set) var isAutomationOn: Bool
    private(set) var isUpdatingAutomation = false
    private(set) var automationError: String?
    private(set) var isSaving = false
    private(set) var saveError: String?

    @ObservationIgnored private let stopRepository: any TransitStopRepository
    @ObservationIgnored private let departureRepository: any DepartureRepository
    @ObservationIgnored private let settings: any UserSettingsRepository
    @ObservationIgnored private let locationProvider: any LocationProvider
    @ObservationIgnored private let walkingRoute: any WalkingRouteService
    @ObservationIgnored private let automation: any CommuteAutomationControlling
    @ObservationIgnored private let dateProvider: any DateProvider
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private let estimateWalk: EstimateWalkingTimeUseCase
    @ObservationIgnored private let planDeparture: PlanDepartureUseCase

    init(
        stopRepository: any TransitStopRepository,
        departureRepository: any DepartureRepository,
        settings: any UserSettingsRepository,
        locationProvider: any LocationProvider,
        walkingRoute: any WalkingRouteService,
        automation: any CommuteAutomationControlling,
        dateProvider: any DateProvider,
        calendar: Calendar = .seoul,
        estimateWalk: EstimateWalkingTimeUseCase = EstimateWalkingTimeUseCase(),
        planDeparture: PlanDepartureUseCase = PlanDepartureUseCase()
    ) {
        self.stopRepository = stopRepository
        self.departureRepository = departureRepository
        self.settings = settings
        self.locationProvider = locationProvider
        self.walkingRoute = walkingRoute
        self.automation = automation
        self.dateProvider = dateProvider
        self.calendar = calendar
        self.estimateWalk = estimateWalk
        self.planDeparture = planDeparture
        self.favoriteStopIDs = Set(settings.favoriteStops().map(\.id))
        self.home = settings.homeLocation()
        self.isAutomationOn = automation.isEnabled
    }

    private var selectedStop: TransitStop? {
        stops.value?.first { $0.id == selectedStopID }
    }

    var display: NearbyDisplayModel {
        NearbyDisplayModel(
            locationText: location.value.map(Self.locationText),
            isLocating: location == .loading || stops == .loading,
            pins: (stops.value ?? []).compactMap { stop in
                stop.coordinate.map { coordinate in
                    NearbyDisplayModel.Pin(
                        id: stop.id,
                        name: stop.name,
                        coordinate: coordinate,
                        isSelected: stop.id == selectedStopID,
                        isFavorite: favoriteStopIDs.contains(stop.id)
                    )
                }
            },
            message: message,
            showsOpenSettings: location == .failed(.locationDenied),
            initialCenter: home ?? PolicyConstants.DefaultLocation.coordinate,
            userCoordinate: location.value?.coordinate,
            homeCoordinate: home,
            searchGeneration: searchGeneration,
            resultSummary: stops.value.flatMap { $0.isEmpty ? nil : String(localized: "주변 정류장 \($0.count)곳") },
            home: NearbyDisplayModel.Home(
                title: home == nil
                    ? String(localized: "집에 있을 때 현재 위치를 집으로 설정하면 날씨와 도보 시간을 집 기준으로 계산해요")
                    : String(localized: "집 위치가 설정돼 있어요. 날씨와 도보 시간을 집 기준으로 계산해요"),
                actionTitle: home == nil ? String(localized: "현재 위치를 집으로 설정") : String(localized: "현재 위치로 다시 설정"),
                isSet: home != nil,
                isUpdating: isUpdatingHome
            ),
            automation: NearbyDisplayModel.Automation(
                isOn: isAutomationOn,
                // 이미 켜져 있으면 끌 수는 있어야 한다
                isAvailable: home != nil || isAutomationOn,
                unavailableReason: home == nil && !isAutomationOn ? String(localized: "먼저 위에서 집 위치를 설정하면 켤 수 있어요") : nil,
                isUpdating: isUpdatingAutomation,
                detail: String(localized: "집을 나서면 출발 카운트다운을 끝내고 출근을 기록해요. 정류장 근처에 오면 도착 정보를 알려 드려요"),
                errorMessage: automationError
            ),
            selection: selectedStop.map(selection(for:))
        )
    }

    private var message: String? {
        if case .failed(let error) = location { return error.userMessage }
        if let fix = location.value, !Self.isPreciseEnough(fix) {
            return String(localized: "정확한 위치가 꺼져 있어 주변 정류장을 찾을 수 없어요. 설정에서 '정확한 위치'를 켜 주세요")
        }
        if case .failed(let error) = stops { return error.userMessage }
        if stops.value?.isEmpty == true { return String(localized: "반경 \(PolicyConstants.Location.nearbyRadiusMeters)m 안에 정류장이 없어요") }
        return nil
    }

    private func walkMinutes(for stop: TransitStop) -> Int {
        mapWalkMinutes[stop.id]?.value ?? stop.estimatedWalkMinutes
    }

    private func selection(for stop: TransitStop) -> NearbyDisplayModel.Selection {
        let walkState = mapWalkMinutes[stop.id]
        let source: String = switch walkState {
        case .loaded: home == nil ? String(localized: "지도 도보 경로 · 현재 위치에서") : String(localized: "지도 도보 경로 · 집에서")
        case .loading: String(localized: "지도에서 도보 경로를 계산하는 중")
        default: String(localized: "직선거리로 어림한 시간")
        }
        var detail = [stop.id]
        if let meters = stop.distanceMeters { detail.append(DisplayFormatter.distanceText(meters: meters)) }
        let isFavorite = favoriteStopIDs.contains(stop.id)
        return NearbyDisplayModel.Selection(
            name: stop.name,
            detail: detail.joined(separator: " · "),
            walkMinutesText: String(localized: "\(walkMinutes(for: stop))분"),
            walkSourceText: source,
            isCalculatingWalk: walkState == .loading,
            arrivals: Self.arrivals(
                arrivals[stop.id] ?? .idle,
                isRefreshing: refreshingStopIDs.contains(stop.id),
                walkMinutes: walkMinutes(for: stop),
                now: dateProvider.now,
                calendar: calendar,
                planDeparture: planDeparture
            ),
            actionTitle: isFavorite ? String(localized: "즐겨찾기 저장됨 · 도보 시간 다시 저장") : String(localized: "이 도보 시간으로 즐겨찾기에 추가"),
            isSaving: isSaving,
            errorMessage: saveError
        )
    }

    // MARK: - 주변 정류장

    /// '찾기'를 눌렀을 때 부른다. 위치 권한도 이때 처음 요청한다.
    func findNearby() async {
        location = .loading
        selectedStopID = nil
        do {
            let fix = try await locationProvider.currentLocation()
            location = .loaded(fix, fetchedAt: dateProvider.now)
            guard Self.isPreciseEnough(fix) else {
                stops = .idle
                return
            }
            stops = stops.beginningLoad()
            let found = try await stopRepository.nearbyStops(around: fix.coordinate, radiusMeters: PolicyConstants.Location.nearbyRadiusMeters)
            stops = .loaded(Array(found.prefix(PolicyConstants.Location.nearbyMaxResults)), fetchedAt: dateProvider.now)
            searchGeneration += 1
            // 찾은 정류장이 있으면 지도 화면으로 이동한다 (없으면 검색 화면에 안내 문구를 둔다)
            if !found.isEmpty { isMapPresented = true }
        } catch {
            let appError = AppError(error)
            if location == .loading {
                location = .failed(appError)
            } else {
                stops = .failed(appError)
            }
        }
    }

    /// 핀을 눌렀을 때. 같은 핀을 다시 누르면 선택을 푼다.
    func toggleSelection(stopID: String) {
        selectedStopID = selectedStopID == stopID ? nil : stopID
        saveError = nil
    }

    func clearSelection() {
        selectedStopID = nil
    }

    /// 고른 정류장의 도착 정보와 지도 도보 시간을 함께 불러온다. View의 `.task(id: selectedStopID)`에서 부른다.
    func loadSelection() async {
        async let arrivalsLoaded: Void = refreshArrivals()
        async let walkCalculated: Void = calculateWalkForSelection()
        _ = await (arrivalsLoaded, walkCalculated)
    }

    /// 고른 정류장의 도착 정보를 다시 받는다 (저장소가 30초 캐시를 거친다).
    func refreshArrivals() async {
        guard let stop = selectedStop else { return }
        let previous = arrivals[stop.id] ?? .idle
        arrivals[stop.id] = previous.beginningLoad()
        refreshingStopIDs.insert(stop.id)
        defer { refreshingStopIDs.remove(stop.id) }
        do {
            let result = try await departureRepository.arrivals(at: stop)
            guard !Task.isCancelled else {
                arrivals[stop.id] = previous
                return
            }
            arrivals[stop.id] = (arrivals[stop.id] ?? .idle).resolved(with: .success(result))
        } catch {
            guard !Task.isCancelled else {
                arrivals[stop.id] = previous
                return
            }
            arrivals[stop.id] = (arrivals[stop.id] ?? .idle).resolved(with: .failure(AppError(error)))
        }
    }

    /// 고른 정류장까지 지도 도보 시간을 구한다. 출발점은 집, 집이 없으면 현재 위치.
    func calculateWalkForSelection() async {
        guard let stop = selectedStop, let destination = stop.coordinate, mapWalkMinutes[stop.id]?.value == nil,
              let origin = home ?? location.value?.coordinate else { return }
        mapWalkMinutes[stop.id] = .loading
        do {
            let seconds = try await walkingRoute.walkingSeconds(from: origin, to: destination)
            // 계산하는 동안 집을 다시 설정했으면 이전 출발점 기준 결과라서 버린다
            guard !Task.isCancelled, origin == home ?? location.value?.coordinate else {
                mapWalkMinutes[stop.id] = nil
                return
            }
            mapWalkMinutes[stop.id] = .loaded(estimateWalk.minutes(fromTravelSeconds: seconds), fetchedAt: dateProvider.now)
        } catch {
            guard !Task.isCancelled else {
                mapWalkMinutes[stop.id] = nil
                return
            }
            mapWalkMinutes[stop.id] = .failed(AppError(error))
        }
    }

    /// 고른 정류장을 기본 경로(첫 번째 즐겨찾기)로 저장한다.
    func addSelectedToFavorites() async {
        guard let stop = selectedStop, !isSaving else { return }
        isSaving = true
        saveError = nil
        defer { isSaving = false }
        let routes: [String]
        if let loaded = arrivals[stop.id]?.value, !loaded.isEmpty {
            routes = loaded.map(\.key)
        } else {
            do {
                routes = try await stopRepository.routeNames(for: stop)
            } catch {
                saveError = AppError(error).userMessage
                return
            }
        }
        let saved = settings.favoriteStops().first { $0.id == stop.id }
        settings.saveFavoriteStop(FavoriteStop(
            id: stop.id,
            kind: stop.kind,
            name: stop.name,
            direction: stop.direction,
            walkMinutes: walkMinutes(for: stop),
            trackedRoutes: saved?.trackedRoutes ?? Array(routes.prefix(1)),
            coordinate: stop.coordinate
        ))
        favoriteStopIDs.insert(stop.id)
        await automation.syncRegions()
    }

    // MARK: - 집 · 자동 처리

    /// 집에 있을 때 누른다. 날씨 격자, 도보 경로 출발점, "집을 나섬" 감시에 쓴다.
    func setCurrentLocationAsHome() async {
        isUpdatingHome = true
        defer { isUpdatingHome = false }
        do {
            let fix = try await locationProvider.currentLocation()
            location = .loaded(fix, fetchedAt: dateProvider.now)
            settings.setHomeLocation(fix.coordinate)
            // 지금 집 안에 있으므로, 다음에 밖으로 나가면 "집을 나섬"으로 잡히게 한다
            settings.setLastRegionPresence(.inside, for: .home)
            home = fix.coordinate
            // 출발점이 바뀌었으니 지도 도보 시간을 다시 계산한다
            mapWalkMinutes = [:]
            await automation.syncRegions()
        } catch {
            location = .failed(AppError(error))
        }
    }

    func setAutomation(_ isOn: Bool) async {
        isUpdatingAutomation = true
        automationError = nil
        defer {
            isUpdatingAutomation = false
            isAutomationOn = automation.isEnabled
        }
        do {
            try await automation.setEnabled(isOn)
        } catch {
            automationError = error.userMessage
        }
    }

    // MARK: - 순수 함수

    nonisolated static func isPreciseEnough(_ fix: LocationFix) -> Bool {
        !fix.isAccuracyReduced && fix.horizontalAccuracyMeters <= PolicyConstants.Location.nearbySearchMaxAccuracyMeters
    }

    nonisolated static func locationText(_ fix: LocationFix) -> String {
        fix.isAccuracyReduced
            ? String(localized: "대략적인 위치 기준")
            : String(localized: "현재 위치 기준 · 오차 \(Int(fix.horizontalAccuracyMeters.rounded()))m")
    }

    /// 도착 정보 → 행. 남은 시간이 있는 노선은 도보 시간을 빼서 "N분 뒤 출발"까지 붙인다.
    nonisolated static func arrivals(
        _ state: SectionState<[RouteArrival]>,
        isRefreshing: Bool,
        walkMinutes: Int,
        now: Date,
        calendar: Calendar,
        planDeparture: PlanDepartureUseCase
    ) -> NearbyDisplayModel.Arrivals {
        let rows: ([RouteArrival]) -> [NearbyDisplayModel.ArrivalRow] = { routes in
            routes.map { route in
                let base = StandDisplayMapper.row(route)
                var row = NearbyDisplayModel.ArrivalRow(
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
        }
        switch state {
        case .idle, .loading:
            return .loading
        case .loaded(let routes, let fetchedAt), .stale(let routes, let fetchedAt, _):
            guard !routes.isEmpty else { return .message(String(localized: "지금 도착 정보가 없어요")) }
            let updated = String(localized: "\(DisplayFormatter.elapsedText(from: fetchedAt, to: now, calendar: calendar)) 기준")
            return .rows(rows(routes), updatedText: updated, isRefreshing: isRefreshing)
        case .failed(let error):
            return .message(error.userMessage)
        }
    }

    nonisolated static func departureText(_ plan: DeparturePlan) -> String {
        switch plan.urgency {
        case .relaxed, .soon: String(localized: "\(plan.minutesUntilDeparture)분 뒤 출발")
        case .now: String(localized: "지금 출발")
        case .missed:
            plan.nextDepartureMinutes.map { String(localized: "이번 차 놓침 · 다음 차 \($0)분 뒤 출발") } ?? String(localized: "이번 차 놓침")
        }
    }
}
