import Foundation
import Observation

/// 주변 정류장을 찾으면 지도 화면으로 이동해 핀으로 보여주고, (표시 문구는 `NearbyDisplayMapper`가 만든다) 핀을 고르면 그 정류장의 도착 정보와 지도 도보 시간을 불러온다.
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
        NearbyDisplayMapper.make(
            NearbyDisplayMapper.Input(
                location: location,
                stops: stops,
                searchGeneration: searchGeneration,
                selectedStopID: selectedStopID,
                mapWalkMinutes: mapWalkMinutes,
                arrivals: arrivals,
                refreshingStopIDs: refreshingStopIDs,
                favoriteStopIDs: favoriteStopIDs,
                home: home,
                isUpdatingHome: isUpdatingHome,
                isAutomationOn: isAutomationOn,
                isUpdatingAutomation: isUpdatingAutomation,
                automationError: automationError,
                isSaving: isSaving,
                saveError: saveError,
                now: dateProvider.now
            ),
            calendar: calendar,
            planDeparture: planDeparture
        )
    }

    private func walkMinutes(for stop: TransitStop) -> Int {
        NearbyDisplayMapper.walkMinutes(for: stop, mapWalkMinutes: mapWalkMinutes)
    }

    // MARK: - 주변 정류장

    /// '찾기'를 눌렀을 때 부른다. 위치 권한도 이때 처음 요청한다.
    func findNearby() async {
        location = .loading
        selectedStopID = nil
        do {
            let fix = try await locationProvider.currentLocation()
            location = .loaded(fix, fetchedAt: dateProvider.now)
            guard NearbyDisplayMapper.isPreciseEnough(fix) else {
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
}
