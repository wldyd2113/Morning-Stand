import Foundation
import OSLog

/// 의존성 조립. 실제 구현과 Preview·UI 테스트용 구성을 한곳에서 만든다.
struct AppDependencies {
    let weatherRepository: any WeatherRepository
    let departureRepository: any DepartureRepository
    let commuteRouteRepository: any CommuteRouteRepository
    let transitStopRepository: any TransitStopRepository
    let airQualityStationRepository: any AirQualityStationRepository
    let settingsRepository: any UserSettingsRepository
    let dateProvider: any DateProvider
    let clock: any Clock<Duration>
    let calendar: Calendar
    let forcedPosture: DevicePosture?
    /// 움직임 상태 (실기기는 CoreMotion, 시뮬레이터·Preview는 고정값)
    var motionProvider: any MotionStateProviding = StaticMotionStateProvider(state: .unavailable)
    var initialPlanningTab: PlanningTab = .routes
    let themeOverride: DisplayTheme?
    let snapshotPublisher: any WidgetSnapshotPublishing
    let liveActivity: any LiveActivityControlling
    let locationProvider: any LocationProvider
    let walkingRouteService: any WalkingRouteService
    let historyRepository: any CommuteHistoryRepository
    /// 앱 전체에서 하나. 지역 감시 이벤트를 받아 Live Activity 종료·알림·출근 기록을 처리한다
    let commuteAutomation: CommuteAutomationCoordinator
    var showsLiveActivityAnyTime = false

    /// 앱 실행용 구성. `-useSampleData` 또는 `-standScenario`가 있으면 샘플 데이터를 쓴다.
    static func live(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppDependencies {
        var dependencies = makeLive(arguments: arguments)
        dependencies.showsLiveActivityAnyTime = arguments.contains(AppConstants.LaunchArgument.liveActivityAnyTime)
        dependencies.initialPlanningTab = argumentValue(AppConstants.LaunchArgument.planningTab, in: arguments).flatMap(PlanningTab.init(rawValue:)) ?? .routes
        // 시뮬레이터는 센서가 없어서 -motion으로 흉내 낸다. 없으면 실기기 CoreMotion을 쓴다
        if let motion = argumentValue(AppConstants.LaunchArgument.motion, in: arguments).flatMap(MotionState.init(rawValue:)) {
            dependencies.motionProvider = StaticMotionStateProvider(state: motion)
        } else {
            dependencies.motionProvider = CoreMotionStateProvider()
        }
        return dependencies
    }

    private static func makeLive(arguments: [String]) -> AppDependencies {
        let posture = argumentValue(AppConstants.LaunchArgument.posture, in: arguments).flatMap(DevicePosture.init(rawValue:))
        let theme = argumentValue(AppConstants.LaunchArgument.theme, in: arguments).flatMap(DisplayTheme.init(rawValue:))
        let scenario = argumentValue(AppConstants.LaunchArgument.standScenario, in: arguments).flatMap(StandScenario.init(rawValue:))
        if arguments.contains(AppConstants.LaunchArgument.useSampleData) || scenario != nil {
            return sample(scenario: scenario ?? .soon, dateProvider: SystemDateProvider(), posture: posture, theme: theme, publishesToSystem: true)
        }

        let dateProvider = SystemDateProvider()
        let calendar = Calendar.seoul
        let settings = UserDefaultsSettingsRepository()
        let requester = PublicAPIRequester(apiClient: AlamofireAPIClient(), configuration: SecretsReader.serverConfiguration())
        let fetcher = CachedFetcher(cache: CacheStore(dateProvider: dateProvider), limiter: RateLimiter(dateProvider: dateProvider, calendar: calendar))
        let clock = ContinuousClock()
        let departureRepository = DefaultDepartureRepository(requester: requester, fetcher: fetcher, settings: settings, dateProvider: dateProvider, calendar: calendar)
        let historyRepository = makeHistoryRepository()
        let liveActivity = DepartureLiveActivityController()
        return AppDependencies(
            weatherRepository: DefaultWeatherRepository(requester: requester, fetcher: fetcher, settings: settings, dateProvider: dateProvider, calendar: calendar),
            departureRepository: departureRepository,
            commuteRouteRepository: UserDefaultsCommuteRouteRepository(),
            transitStopRepository: DefaultTransitStopRepository(requester: requester, fetcher: fetcher, dateProvider: dateProvider, calendar: calendar),
            airQualityStationRepository: DefaultAirQualityStationRepository(requester: requester, fetcher: fetcher),
            settingsRepository: settings,
            dateProvider: dateProvider,
            clock: clock,
            calendar: calendar,
            forcedPosture: posture,
            themeOverride: theme,
            snapshotPublisher: WidgetCenterSnapshotPublisher(),
            liveActivity: liveActivity,
            locationProvider: CoreLocationProvider(clock: clock),
            walkingRouteService: MapKitWalkingRouteService(),
            historyRepository: historyRepository,
            commuteAutomation: CommuteAutomationCoordinator(
                settings: settings,
                monitor: CLMonitorCommuteRegionMonitor(),
                notifications: UserNotificationScheduler(),
                departureRepository: departureRepository,
                historyRepository: historyRepository,
                liveActivity: liveActivity,
                dateProvider: dateProvider,
                calendar: calendar
            )
        )
    }

    /// SwiftData 저장소를 열지 못하면(스키마 손상 등) 앱이 멈추지 않도록 메모리 저장소로 대신한다.
    private static func makeHistoryRepository() -> any CommuteHistoryRepository {
        do {
            let container = try CommuteHistoryMigrationPlan.makeContainer(inMemory: false)
            return SwiftDataCommuteHistoryRepository(store: CommuteRecordStore(modelContainer: container))
        } catch {
            Logger(subsystem: AppConstants.Logging.subsystem, category: AppConstants.Logging.historyCategory)
                .error("출근 기록 저장소를 열지 못함: \(String(describing: error), privacy: .public)")
            return InMemoryCommuteHistoryRepository()
        }
    }

    /// Preview용 구성. 시각을 시안과 같은 2026-09-30(수) 07:42 KST로 고정한다.
    static func preview(scenario: StandScenario = .soon, posture: DevicePosture? = nil, theme: DisplayTheme? = nil) -> AppDependencies {
        let fixedDate = Calendar.seoul.date(from: DateComponents(year: 2026, month: 9, day: 30, hour: 7, minute: 42)) ?? .distantPast
        return sample(scenario: scenario, dateProvider: FixedDateProvider(now: fixedDate), posture: posture, theme: theme, publishesToSystem: false)
    }

    private static func sample(scenario: StandScenario, dateProvider: any DateProvider, posture: DevicePosture?, theme: DisplayTheme?, publishesToSystem: Bool) -> AppDependencies {
        let clock = ContinuousClock()
        let settings = InMemorySettingsRepository(favorites: SampleTransitStopRepository.favorites)
        let departureRepository = SampleDepartureRepository(scenario: scenario, dateProvider: dateProvider, clock: clock)
        let historyRepository = InMemoryCommuteHistoryRepository(records: InMemoryCommuteHistoryRepository.sampleRecords(endingAt: dateProvider.now, calendar: .seoul))
        let liveActivity: any LiveActivityControlling = publishesToSystem ? DepartureLiveActivityController() : NoopLiveActivityController()
        return AppDependencies(
            weatherRepository: SampleWeatherRepository(scenario: scenario, dateProvider: dateProvider, clock: clock),
            departureRepository: departureRepository,
            commuteRouteRepository: SampleCommuteRouteRepository(),
            transitStopRepository: SampleTransitStopRepository(),
            airQualityStationRepository: SampleAirQualityStationRepository(),
            settingsRepository: settings,
            dateProvider: dateProvider,
            clock: clock,
            calendar: .seoul,
            forcedPosture: posture,
            themeOverride: theme,
            snapshotPublisher: publishesToSystem ? WidgetCenterSnapshotPublisher() : NoopWidgetSnapshotPublisher(),
            liveActivity: liveActivity,
            locationProvider: SampleLocationProvider(),
            walkingRouteService: SampleWalkingRouteService(),
            historyRepository: historyRepository,
            commuteAutomation: CommuteAutomationCoordinator(
                settings: settings,
                monitor: NoopCommuteRegionMonitor(),
                notifications: NoopCommuteNotificationScheduler(),
                departureRepository: departureRepository,
                historyRepository: historyRepository,
                liveActivity: liveActivity,
                dateProvider: dateProvider,
                calendar: .seoul
            )
        )
    }

    private static func argumentValue(_ flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    // MARK: - ViewModel 팩토리

    func makeRootViewModel() -> RootViewModel {
        RootViewModel(forcedPosture: forcedPosture, initialPlanningTab: initialPlanningTab, motionProvider: motionProvider, clock: clock)
    }

    func makeStandViewModel() -> StandViewModel {
        StandViewModel(
            weatherRepository: weatherRepository,
            departureRepository: departureRepository,
            dateProvider: dateProvider,
            clock: clock,
            calendar: calendar,
            themeOverride: themeOverride,
            snapshotPublisher: snapshotPublisher,
            liveActivity: liveActivity,
            showsLiveActivityAnyTime: showsLiveActivityAnyTime
        )
    }

    func makePlanningViewModel() -> PlanningViewModel {
        PlanningViewModel(repository: commuteRouteRepository, dateProvider: dateProvider, calendar: calendar) { route, onFinish in
            makeRouteEditorViewModel(route: route, onFinish: onFinish)
        }
    }

    func makeRouteEditorViewModel(route: CommuteRoute?, onFinish: @escaping @MainActor () -> Void) -> RouteEditorViewModel {
        RouteEditorViewModel(
            route: route,
            repository: commuteRouteRepository,
            settings: settingsRepository,
            stopRepository: transitStopRepository,
            dateProvider: dateProvider,
            clock: clock,
            calendar: calendar,
            onFinish: onFinish
        )
    }

    func makeNearbyStopsViewModel() -> NearbyStopsViewModel {
        NearbyStopsViewModel(
            stopRepository: transitStopRepository,
            departureRepository: departureRepository,
            settings: settingsRepository,
            locationProvider: locationProvider,
            walkingRoute: walkingRouteService,
            automation: commuteAutomation,
            dateProvider: dateProvider,
            calendar: calendar
        )
    }

    func makeCommuteHistoryViewModel() -> CommuteHistoryViewModel {
        CommuteHistoryViewModel(repository: historyRepository, automation: commuteAutomation, dateProvider: dateProvider, calendar: calendar)
    }

    func makeStopSearchViewModel() -> StopSearchViewModel {
        StopSearchViewModel(repository: transitStopRepository, settings: settingsRepository, dateProvider: dateProvider, clock: clock)
    }

    func makeAirQualityStationViewModel() -> AirQualityStationViewModel {
        AirQualityStationViewModel(repository: airQualityStationRepository, settings: settingsRepository, dateProvider: dateProvider)
    }

    func makeNotificationSettingsViewModel() -> NotificationSettingsViewModel {
        let favorite = settingsRepository.favoriteStops().first
        return NotificationSettingsViewModel(
            preview: .init(
                routeTitle: favorite?.trackedRoutes.first ?? String(localized: "1711번"),
                vehicleText: favorite?.kind == .subway ? String(localized: "열차") : String(localized: "버스"),
                walkMinutes: favorite?.walkMinutes ?? PolicyConstants.Walking.defaultMinutes,
                rainStartHour: nil
            ),
            dateProvider: dateProvider,
            calendar: calendar
        )
    }
}
