import Foundation
import Observation

/// 스탠드 화면 상태. 날씨와 도착 정보를 따로 불러와 섹션별 상태로 가진다.
@MainActor @Observable
final class StandViewModel {
    private(set) var weather: SectionState<WeatherSummary> = .idle
    private(set) var departures: SectionState<DepartureBoard> = .idle
    private(set) var now: Date

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
        showsLiveActivityAnyTime: Bool = false
    ) {
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
        let content = showsLiveActivityAnyTime || Self.isCommuteHour(now, calendar: calendar)
            ? DashboardSnapshotMapper.liveActivityContent(departures: departures, now: now, planDeparture: planDeparture)
            : nil
        await liveActivity.sync(content)
    }

    /// 날씨와 도착 정보를 동시에 불러온다. 먼저 끝난 섹션부터 반영하고, 한쪽이 실패해도 다른 쪽은 그대로 보여준다.
    func load() async {
        now = dateProvider.now
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
