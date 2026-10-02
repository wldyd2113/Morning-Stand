import Foundation

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
    let themeOverride: DisplayTheme?
    let snapshotPublisher: any WidgetSnapshotPublishing
    let liveActivity: any LiveActivityControlling
    var showsLiveActivityAnyTime = false

    /// 앱 실행용 구성. `-useSampleData` 또는 `-standScenario`가 있으면 샘플 데이터를 쓴다.
    static func live(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppDependencies {
        var dependencies = makeLive(arguments: arguments)
        dependencies.showsLiveActivityAnyTime = arguments.contains(AppConstants.LaunchArgument.liveActivityAnyTime)
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
        return AppDependencies(
            weatherRepository: DefaultWeatherRepository(requester: requester, fetcher: fetcher, settings: settings, dateProvider: dateProvider, calendar: calendar),
            departureRepository: DefaultDepartureRepository(requester: requester, fetcher: fetcher, settings: settings, dateProvider: dateProvider, calendar: calendar),
            commuteRouteRepository: UserDefaultsCommuteRouteRepository(),
            transitStopRepository: DefaultTransitStopRepository(requester: requester, fetcher: fetcher, dateProvider: dateProvider, calendar: calendar),
            airQualityStationRepository: DefaultAirQualityStationRepository(requester: requester, fetcher: fetcher),
            settingsRepository: settings,
            dateProvider: dateProvider,
            clock: ContinuousClock(),
            calendar: calendar,
            forcedPosture: posture,
            themeOverride: theme,
            snapshotPublisher: WidgetCenterSnapshotPublisher(),
            liveActivity: DepartureLiveActivityController()
        )
    }

    /// Preview용 구성. 시각을 시안과 같은 2026-09-30(수) 07:42 KST로 고정한다.
    static func preview(scenario: StandScenario = .soon, posture: DevicePosture? = nil, theme: DisplayTheme? = nil) -> AppDependencies {
        let fixedDate = Calendar.seoul.date(from: DateComponents(year: 2026, month: 9, day: 30, hour: 7, minute: 42)) ?? .distantPast
        return sample(scenario: scenario, dateProvider: FixedDateProvider(now: fixedDate), posture: posture, theme: theme, publishesToSystem: false)
    }

    private static func sample(scenario: StandScenario, dateProvider: any DateProvider, posture: DevicePosture?, theme: DisplayTheme?, publishesToSystem: Bool) -> AppDependencies {
        let clock = ContinuousClock()
        return AppDependencies(
            weatherRepository: SampleWeatherRepository(scenario: scenario, dateProvider: dateProvider, clock: clock),
            departureRepository: SampleDepartureRepository(scenario: scenario, dateProvider: dateProvider, clock: clock),
            commuteRouteRepository: SampleCommuteRouteRepository(),
            transitStopRepository: SampleTransitStopRepository(),
            airQualityStationRepository: SampleAirQualityStationRepository(),
            settingsRepository: InMemorySettingsRepository(favorites: SampleTransitStopRepository.favorites),
            dateProvider: dateProvider,
            clock: clock,
            calendar: .seoul,
            forcedPosture: posture,
            themeOverride: theme,
            snapshotPublisher: publishesToSystem ? WidgetCenterSnapshotPublisher() : NoopWidgetSnapshotPublisher(),
            liveActivity: publishesToSystem ? DepartureLiveActivityController() : NoopLiveActivityController()
        )
    }

    private static func argumentValue(_ flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    // MARK: - ViewModel 팩토리

    func makeRootViewModel() -> RootViewModel {
        RootViewModel(forcedPosture: forcedPosture)
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
