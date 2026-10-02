import Foundation
import OSLog

/// 지역 감시 이벤트를 받아 Live Activity 종료, 정류장 근처 알림, 출근 기록을 처리한다.
/// 앱 진입점(`MoningseutendeuApp.init`)에서 `run()`을 시작한다. 화면(Scene)과 상관없이 시작하므로
/// 지역 감시 이벤트로 앱이 백그라운드에서 다시 실행돼 화면이 만들어지지 않아도 이벤트를 받는다.
final class CommuteAutomationCoordinator: CommuteAutomationControlling {
    private let settings: any UserSettingsRepository
    private let monitor: any CommuteRegionMonitoring
    private let notifications: any CommuteNotificationScheduling
    private let departureRepository: any DepartureRepository
    private let historyRepository: any CommuteHistoryRepository
    private let liveActivity: any LiveActivityControlling
    private let dateProvider: any DateProvider
    private let calendar: Calendar
    private let planDeparture: PlanDepartureUseCase
    private let detectEvent = DetectCommuteRegionEventUseCase()
    private let recordCommute = RecordCommuteUseCase()
    private let commuteHours = CommuteHourPolicy.standard
    /// 기록 읽기 → 진행 중 기록 찾기 → 저장 사이에 await가 있어서, 겹치면 기록이 두 건 생긴다. 앞 작업이 끝난 뒤 실행한다
    private var recordingTask: Task<Void, Never>?
    private let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: AppConstants.Logging.historyCategory)

    init(
        settings: any UserSettingsRepository,
        monitor: any CommuteRegionMonitoring,
        notifications: any CommuteNotificationScheduling,
        departureRepository: any DepartureRepository,
        historyRepository: any CommuteHistoryRepository,
        liveActivity: any LiveActivityControlling,
        dateProvider: any DateProvider,
        calendar: Calendar = .seoul,
        planDeparture: PlanDepartureUseCase = PlanDepartureUseCase()
    ) {
        self.settings = settings
        self.monitor = monitor
        self.notifications = notifications
        self.departureRepository = departureRepository
        self.historyRepository = historyRepository
        self.liveActivity = liveActivity
        self.dateProvider = dateProvider
        self.calendar = calendar
        self.planDeparture = planDeparture
    }

    var isEnabled: Bool { settings.isCommuteAutomationEnabled() }

    /// 지역 감시 이벤트를 계속 받는다. View의 `.task`에서 부르면 앱이 끝날 때 취소된다.
    func run() async {
        await syncRegions()
        for await change in await monitor.presenceChanges() {
            await handle(change)
        }
    }

    func setEnabled(_ isEnabled: Bool) async throws(CommuteAutomationError) {
        guard isEnabled else {
            settings.setCommuteAutomationEnabled(false)
            await syncRegions()
            return
        }
        guard settings.homeLocation() != nil else { throw .homeNotSet }
        guard await monitor.requestAlwaysAuthorization() else { throw .alwaysLocationDenied }
        // 알림은 거부돼도 기록과 Live Activity 종료는 동작하므로 결과를 막지 않는다
        _ = await notifications.requestAuthorization()
        settings.setCommuteAutomationEnabled(true)
        await syncRegions()
    }

    func syncRegions() async {
        guard isEnabled else {
            await monitor.monitor(home: nil, stop: nil)
            return
        }
        await monitor.monitor(home: settings.homeLocation(), stop: settings.favoriteStops().first?.coordinate)
    }

    func recordLeavingNow() async throws {
        guard let favorite = settings.favoriteStops().first else { throw AppError.notConfigured }
        let now = dateProvider.now
        let board = try? await departureRepository.fetchDepartureBoard().value
        let plan = board.flatMap(plan(for:))
        var failure: (any Error)?
        await serializedRecording { [self] in
            do {
                let records = try await historyRepository.records(since: calendar.startOfDay(for: now))
                let open = recordCommute.openRecord(in: records, at: now)
                let record = recordCommute.leftHomeManually(at: now, favorite: favorite, board: board, plan: plan, openRecord: open)
                try await historyRepository.save(record)
            } catch {
                failure = error
            }
        }
        if let failure { throw failure }
    }

    /// 출근 기록을 바꾸는 작업을 한 번에 하나씩 실행한다.
    private func serializedRecording(_ operation: @escaping @MainActor () async -> Void) async {
        let previous = recordingTask
        let task = Task {
            await previous?.value
            await operation()
        }
        recordingTask = task
        await task.value
    }

    // MARK: - 이벤트 처리

    func handle(_ change: RegionPresenceChange) async {
        let previous = settings.lastRegionPresence(change.region)
        settings.setLastRegionPresence(change.presence, for: change.region)
        guard isEnabled, let event = detectEvent(region: change.region, previous: previous, current: change.presence, at: change.date) else { return }
        switch event {
        case .leftHome(let date): await handleLeftHome(at: date)
        case .nearStop(let date): await handleNearStop(at: date)
        }
    }

    /// 집을 나서면 Live Activity는 끝낸다 (이미 출발했으니 카운트다운이 필요 없다). 출근 시간대면 기록을 시작한다.
    private func handleLeftHome(at date: Date) async {
        await liveActivity.sync(nil)
        guard commuteHours.contains(date, calendar: calendar), let favorite = settings.favoriteStops().first else { return }
        let board = try? await departureRepository.fetchDepartureBoard().value
        let plan = board.flatMap(plan(for:))
        await serializedRecording { [self] in
            do {
                let records = try await historyRepository.records(since: calendar.startOfDay(for: date))
                let open = recordCommute.openRecord(in: records, at: date)
                try await historyRepository.save(recordCommute.leftHome(at: date, favorite: favorite, plan: plan, openRecord: open))
            } catch {
                logger.error("출발 기록 실패: \(String(describing: error), privacy: .public)")
            }
        }
    }

    /// 정류장 근처에 오면 지금 오는 차량을 알리고, 진행 중인 출근 기록에 탑승 정보를 채운다.
    private func handleNearStop(at date: Date) async {
        // 출근과 상관없이 정류장 근처를 지날 때마다 서울 버스 한도를 쓰고 알림을 보내지 않게 한다
        guard commuteHours.contains(date, calendar: calendar) else { return }
        let board = try? await departureRepository.fetchDepartureBoard().value
        if let board {
            let message = Self.nearStopMessage(board: board)
            await notifications.notifyNearStop(title: message.title, body: message.body)
        }
        await serializedRecording { [self] in
            do {
                let records = try await historyRepository.records(since: calendar.startOfDay(for: date))
                guard let open = recordCommute.openRecord(in: records, at: date) else { return }
                try await historyRepository.save(recordCommute.reachedStop(open, at: date, board: board))
            } catch {
                logger.error("정류장 도착 기록 실패: \(String(describing: error), privacy: .public)")
            }
        }
    }

    private func plan(for board: DepartureBoard) -> DeparturePlan? {
        guard case .arriving(let minutes, let next) = board.primary.status else { return nil }
        return planDeparture(arrivalMinutes: minutes, nextArrivalMinutes: next, walkMinutes: board.walkMinutes)
    }

    /// "1711번 곧 도착" / "1711번 3분 뒤 도착 · 다음 차 12분". 알림은 나중에 읽힐 수 있어서 상대 시간을 짧게만 쓴다.
    nonisolated static func nearStopMessage(board: DepartureBoard) -> (title: String, body: String) {
        let route = board.primary.kind == .bus ? String(localized: "\(board.primary.routeName)번") : board.primary.routeName
        let title = String(localized: "\(board.primary.stopName) 근처예요")
        let body: String = switch board.primary.status {
        case .arriving(let minutes, let next) where minutes <= 0:
            next.map { String(localized: "\(route) 곧 도착 · 다음 차 \($0)분") } ?? String(localized: "\(route) 곧 도착")
        case .arriving(let minutes, let next):
            next.map { String(localized: "\(route) \(minutes)분 뒤 도착 · 다음 차 \($0)분") } ?? String(localized: "\(route) \(minutes)분 뒤 도착")
        case .ended:
            String(localized: "\(route) 운행이 끝났어요")
        case .message(let text):
            "\(route) \(text)"
        }
        return (title, body)
    }
}
