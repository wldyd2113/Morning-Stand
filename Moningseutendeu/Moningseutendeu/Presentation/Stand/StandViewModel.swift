import Foundation
import Observation

/// 스탠드 화면 상태. 날씨와 도착 정보를 따로 불러와 섹션별 상태로 가진다.
@MainActor @Observable
final class StandViewModel {
    private(set) var weather: SectionState<WeatherSummary> = .idle
    private(set) var departures: SectionState<DepartureBoard> = .idle
    private(set) var now: Date
    /// 즐겨찾기 정류장 (첫 번째가 지금 보여주는 정류장)
    private(set) var favorites: [FavoriteStop] = []
    /// 예약한 출발 알림 시각
    private(set) var reminderAt: Date?
    /// 정류장·노선을 바꾸면 늘린다. View가 `.task(id:)`로 다시 불러온다
    private(set) var reloadToken = 0

    @ObservationIgnored private let weatherRepository: any WeatherRepository
    @ObservationIgnored private let departureRepository: any DepartureRepository
    @ObservationIgnored private let dateProvider: any DateProvider
    @ObservationIgnored private let clock: any Clock<Duration>
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private let themeOverride: DisplayTheme?
    @ObservationIgnored private let planDeparture: PlanDepartureUseCase
    @ObservationIgnored private let snapshotPublisher: any WidgetSnapshotPublishing
    @ObservationIgnored private let liveActivity: any LiveActivityControlling
    @ObservationIgnored private let showsLiveActivityAnyTime: Bool
    /// 접어서 들고 나갔을 때 시작한 Live Activity. 도착 정보가 없어질 때까지 시간대와 상관없이 유지한다
    @ObservationIgnored private var isLiveActivityHandedOff = false
    @ObservationIgnored private let settings: any UserSettingsRepository
    @ObservationIgnored private let notifications: any CommuteNotificationScheduling

    init(
        weatherRepository: any WeatherRepository,
        departureRepository: any DepartureRepository,
        dateProvider: any DateProvider,
        clock: any Clock<Duration>,
        calendar: Calendar = .seoul,
        themeOverride: DisplayTheme? = nil,
        planDeparture: PlanDepartureUseCase = PlanDepartureUseCase(),
        snapshotPublisher: any WidgetSnapshotPublishing = NoopWidgetSnapshotPublisher(),
        liveActivity: any LiveActivityControlling = NoopLiveActivityController(),
        showsLiveActivityAnyTime: Bool = false,
        settings: any UserSettingsRepository = InMemorySettingsRepository(),
        notifications: any CommuteNotificationScheduling = NoopCommuteNotificationScheduler()
    ) {
        self.settings = settings
        self.notifications = notifications
        self.showsLiveActivityAnyTime = showsLiveActivityAnyTime
        self.planDeparture = planDeparture
        self.snapshotPublisher = snapshotPublisher
        self.liveActivity = liveActivity
        self.weatherRepository = weatherRepository
        self.departureRepository = departureRepository
        self.dateProvider = dateProvider
        self.clock = clock
        self.calendar = calendar
        self.themeOverride = themeOverride
        self.now = dateProvider.now
    }

    var theme: DisplayTheme {
        themeOverride ?? DisplayTheme.resolve(at: now, calendar: calendar)
    }

    var display: StandDisplayModel {
        StandDisplayMapper.make(weather: weather, departures: departures, theme: theme, now: now, calendar: calendar, planDeparture: planDeparture)
    }

    func clock(at date: Date) -> StandDisplayModel.Clock {
        StandDisplayMapper.clock(at: date, calendar: calendar)
    }

    func footerText(_ footer: StandDisplayModel.Footer, at date: Date) -> String {
        StandDisplayMapper.footerText(footer, at: date, calendar: calendar)
    }

    // MARK: - 아래쪽 조작판

    var controls: StandControlsDisplayModel {
        StandControlsDisplayModel(
            stopTitle: favorites.first?.name,
            stopPosition: favorites.count > 1 ? "1/\(favorites.count)" : nil,
            canSwitchStop: favorites.count > 1,
            reminder: reminderDisplay
        )
    }

    private var reminderDisplay: StandControlsDisplayModel.Reminder {
        if let reminderAt, reminderAt > now {
            let time = DisplayFormatter.meridiemTimeText(TimeOfDay(date: reminderAt, calendar: calendar), on: reminderAt, calendar: calendar)
            return .scheduled(title: String(localized: "\(time)에 알려드려요"), detail: String(localized: "누르면 취소"))
        }
        guard departAt != nil else { return .unavailable }
        return .available(title: String(localized: "출발 \(PolicyConstants.Notification.defaultDepartureLeadMinutes)분 전 알림"))
    }

    /// 지금 보여주는 노선을 타려면 집을 나서야 하는 시각. 이번 차를 걸어서 못 타면 다음 차 기준
    private var departAt: Date? {
        let board: DepartureBoard
        let fetchedAt: Date
        switch departures {
        case .loaded(let value, let date), .stale(let value, let date, .refreshFailed):
            board = value
            fetchedAt = date
        default:
            return nil
        }
        guard case .arriving(let minutes, let nextMinutes) = board.primary.status else { return nil }
        let candidates = [minutes, nextMinutes].compactMap { $0 }.map { arrival in
            fetchedAt.addingTimeInterval(TimeInterval((arrival - board.walkMinutes) * 60))
        }
        return candidates.first { $0 > now }
    }

    /// 다음 즐겨찾기 정류장으로 넘긴다 (순서를 한 칸 돌려 저장).
    func showNextStop() {
        rotateFavorites(by: 1)
    }

    /// 이전 즐겨찾기 정류장으로 넘긴다.
    func showPreviousStop() {
        rotateFavorites(by: -1)
    }

    private func rotateFavorites(by offset: Int) {
        guard favorites.count > 1 else { return }
        let shift = (offset % favorites.count + favorites.count) % favorites.count
        let rotated = Array(favorites[shift...] + favorites[..<shift])
        settings.setFavoriteStops(rotated)
        favorites = rotated
        // 이전 정류장의 도착 정보를 잠깐이라도 보여주지 않게 비우고 다시 불러온다
        departures = .loading
        reminderAt = nil
        reloadToken += 1
    }

    /// "다른 노선"에서 고른 노선을 카운트다운 카드로 올리고, 다음에도 먼저 보여주도록 저장한다.
    func pinRoute(id: String) {
        guard var favorite = favorites.first,
              let route = departures.value?.others.first(where: { $0.id == id }) else { return }
        favorite.trackedRoutes = [route.key] + favorite.trackedRoutes.filter { $0 != route.key }
        settings.saveFavoriteStop(favorite)
        favorites = settings.favoriteStops()
        reminderAt = nil
        reloadToken += 1
    }

    /// 출발 N분 전 알림을 예약하거나, 이미 예약했으면 취소한다.
    func toggleDepartureReminder() async {
        if let reminderAt, reminderAt > now {
            await notifications.cancelDepartureReminder()
            self.reminderAt = nil
            return
        }
        guard let departAt, let board = departures.value else { return }
        let lead = PolicyConstants.Notification.defaultDepartureLeadMinutes
        let fireAt = max(departAt.addingTimeInterval(-TimeInterval(lead * 60)), now)
        guard await notifications.requestAuthorization() else { return }
        let route = StandDisplayMapper.routeTitle(board.primary)
        let departText = DisplayFormatter.meridiemTimeText(TimeOfDay(date: departAt, calendar: calendar), on: departAt, calendar: calendar)
        let scheduled = await notifications.scheduleDepartureReminder(
            at: fireAt,
            title: String(localized: "\(route) · \(departText)에 출발하세요"),
            body: String(localized: "\(board.primary.stopName)까지 도보 \(board.walkMinutes)분")
        )
        reminderAt = scheduled ? fireAt : nil
    }

    /// 스탠드 화면을 보다가 접었을 때: 출근 시간대가 아니어도 Live Activity를 시작해서 Dynamic Island로 이어준다.
    func handOffToLiveActivity() async {
        isLiveActivityHandedOff = true
        await publishToSystemSurfaces()
    }

    /// 화면이 보이는 동안 실행한다. View의 `.task`에서 부르면 화면을 떠날 때 자동으로 취소된다.
    /// 1분마다 시각을 갱신하고, 갱신 주기(출근 시간대 1분, 그 외 5분)가 지나면 다시 불러온다.
    func start() async {
        await load()
        var lastLoadedAt = dateProvider.now
        while !Task.isCancelled {
            do {
                try await clock.sleep(for: PolicyConstants.Stand.minuteTickInterval)
            } catch {
                return
            }
            now = dateProvider.now
            if now.timeIntervalSince(lastLoadedAt) >= Self.refreshInterval(at: now, calendar: calendar).timeInterval {
                await load()
                lastLoadedAt = now
            }
        }
    }

    /// 서울 버스 일일 1,000건 한도 때문에 출근 시간대에만 자주 갱신한다.
    nonisolated static func refreshInterval(at date: Date, calendar: Calendar) -> Duration {
        isCommuteHour(date, calendar: calendar) ? PolicyConstants.Polling.commuteInterval : PolicyConstants.Polling.offPeakInterval
    }

    nonisolated static func isCommuteHour(_ date: Date, calendar: Calendar) -> Bool {
        CommuteHourPolicy.standard.contains(date, calendar: calendar)
    }

    /// 불러온 결과를 위젯 스냅샷과 Live Activity에 반영한다. Live Activity는 출근 시간대에만 띄운다.
    private func publishToSystemSurfaces() async {
        if let snapshot = DashboardSnapshotMapper.snapshot(weather: weather, departures: departures, theme: theme, now: now, calendar: calendar, planDeparture: planDeparture) {
            snapshotPublisher.publish(snapshot)
        }
        let wantsLiveActivity = showsLiveActivityAnyTime || isLiveActivityHandedOff || Self.isCommuteHour(now, calendar: calendar)
        let content = wantsLiveActivity
            ? DashboardSnapshotMapper.liveActivityContent(departures: departures, now: now, planDeparture: planDeparture)
            : nil
        if content == nil { isLiveActivityHandedOff = false }
        await liveActivity.sync(content)
    }

    /// 날씨와 도착 정보를 동시에 불러온다. 먼저 끝난 섹션부터 반영하고, 한쪽이 실패해도 다른 쪽은 그대로 보여준다.
    func load() async {
        now = dateProvider.now
        favorites = settings.favoriteStops()
        weather = weather.beginningLoad()
        departures = departures.beginningLoad()

        let weatherRepository = weatherRepository
        let departureRepository = departureRepository
        await withTaskGroup(of: SectionResult.self) { group in
            group.addTask {
                .weather(await Self.capture { try await weatherRepository.fetchCurrentWeather() })
            }
            group.addTask {
                .departures(await Self.capture { try await departureRepository.fetchDepartureBoard() })
            }
            for await result in group {
                guard !Task.isCancelled else { return }
                switch result {
                case .weather(let result): weather = weather.resolved(with: result)
                case .departures(let result): departures = departures.resolved(with: result)
                }
            }
        }
        guard !Task.isCancelled else { return }
        await publishToSystemSurfaces()
    }

    private enum SectionResult: Sendable {
        case weather(Result<Timestamped<WeatherSummary>, AppError>)
        case departures(Result<Timestamped<DepartureBoard>, AppError>)
    }

    private nonisolated static func capture<Value: Sendable>(
        _ operation: @Sendable () async throws -> Value
    ) async -> Result<Value, AppError> {
        do {
            return .success(try await operation())
        } catch {
            return .failure(AppError(error))
        }
    }
}
