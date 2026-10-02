import CoreLocation
import Foundation
import OSLog

/// 집·정류장 원형 지역을 `CLMonitor`로 감시한다.
/// - 같은 이름의 모니터를 다시 열면 앱이 꺼졌다 켜져도 조건과 이벤트가 이어진다.
/// - 앱이 꺼져 있어도 이벤트를 받으려면 "항상" 권한과 `CLServiceSession(.always)`이 필요하다.
/// - actor 재진입 주의: 모니터 열기는 Task 하나로 공유하고, 감시 지역 변경은 앞 요청이 끝난 뒤 순서대로 적용한다.
actor CLMonitorCommuteRegionMonitor: CommuteRegionMonitoring {
    private var openTask: Task<CLMonitor, Never>?
    private var eventTask: Task<Void, Never>?
    private var applyTask: Task<Void, Never>?
    private var alwaysSession: CLServiceSession?
    /// 지금 구독 중인 스트림. 구독은 한 곳(코디네이터)만 하므로 새로 구독하면 이전 스트림은 끝낸다
    private var subscriber: (id: UUID, continuation: AsyncStream<RegionPresenceChange>.Continuation)?
    private let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: AppConstants.Logging.locationCategory)

    deinit {
        eventTask?.cancel()
        subscriber?.continuation.finish()
    }

    /// 구독할 때마다 새 스트림을 만든다. 구독하던 Task가 취소돼 스트림이 끝나도 다시 구독할 수 있다.
    func presenceChanges() async -> AsyncStream<RegionPresenceChange> {
        _ = await openMonitor()
        let (stream, continuation) = AsyncStream.makeStream(of: RegionPresenceChange.self, bufferingPolicy: .bufferingNewest(CommuteRegion.allCases.count * 2))
        let id = UUID()
        subscriber?.continuation.finish()
        subscriber = (id, continuation)
        continuation.onTermination = { [weak self] _ in
            Task { await self?.unsubscribe(id: id) }
        }
        return stream
    }

    /// 감시 지역 변경. 켰다가 바로 끄는 경우처럼 연달아 불려도 요청 순서대로 적용한다.
    func monitor(home: Coordinate?, stop: Coordinate?) async {
        let previous = applyTask
        let task = Task {
            await previous?.value
            await self.apply(home: home, stop: stop)
        }
        applyTask = task
        await task.value
    }

    func requestAlwaysAuthorization() async -> Bool {
        let session = alwaysSession ?? CLServiceSession(authorization: .always)
        alwaysSession = session
        var isGranted = false
        do {
            for try await diagnostic in session.diagnostics where !diagnostic.authorizationRequestInProgress {
                isGranted = !(diagnostic.authorizationDenied || diagnostic.authorizationDeniedGlobally || diagnostic.authorizationRestricted || diagnostic.alwaysAuthorizationDenied)
                break
            }
        } catch {
            logger.error("위치 권한 상태를 받지 못함: \(error.localizedDescription, privacy: .public)")
        }
        // 거부됐는데 감시 중인 지역도 없으면 세션을 남겨 두지 않는다
        if !isGranted, await openMonitor().identifiers.isEmpty {
            alwaysSession?.invalidate()
            alwaysSession = nil
        }
        return isGranted
    }

    // MARK: - 내부

    private func unsubscribe(id: UUID) {
        guard subscriber?.id == id else { return }
        subscriber = nil
    }

    private func deliver(_ change: RegionPresenceChange) {
        subscriber?.continuation.yield(change)
    }

    /// 이벤트 루프가 에러로 끝나면 다음 요청 때 모니터를 다시 연다.
    private func resetAfterEventFailure() {
        openTask = nil
        eventTask = nil
    }

    /// 동시에 여러 번 불려도 CLMonitor는 하나만 연다 (생성 중인 Task를 공유한다).
    private func openMonitor() async -> CLMonitor {
        if let openTask { return await openTask.value }
        let task = Task { await CLMonitor(AppConstants.RegionMonitor.monitorName) }
        openTask = task
        let monitor = await task.value
        if eventTask == nil {
            eventTask = Task { await self.listen(to: monitor) }
        }
        return monitor
    }

    private func listen(to monitor: CLMonitor) async {
        do {
            for try await event in await monitor.events {
                guard let region = CommuteRegion(rawValue: event.identifier) else { continue }
                let presence: RegionPresence? = switch event.state {
                case .satisfied: .inside
                case .unsatisfied: .outside
                default: nil
                }
                guard let presence else { continue }
                deliver(RegionPresenceChange(region: region, presence: presence, date: event.date))
            }
        } catch {
            logger.error("지역 감시 이벤트 중단: \(error.localizedDescription, privacy: .public)")
        }
        resetAfterEventFailure()
    }

    private func apply(home: Coordinate?, stop: Coordinate?) async {
        let monitor = await openMonitor()
        await apply(home, region: .home, radius: PolicyConstants.RegionMonitor.homeRadiusMeters, to: monitor)
        await apply(stop, region: .stop, radius: PolicyConstants.RegionMonitor.stopRadiusMeters, to: monitor)
        if home == nil && stop == nil {
            alwaysSession?.invalidate()
            alwaysSession = nil
        } else if alwaysSession == nil {
            alwaysSession = CLServiceSession(authorization: .always)
        }
    }

    /// 이미 같은 중심·반경으로 감시 중이면 그대로 둔다 (다시 추가하면 상태가 "모름"으로 초기화된다).
    private func apply(_ coordinate: Coordinate?, region: CommuteRegion, radius: Double, to monitor: CLMonitor) async {
        let identifier = region.rawValue
        guard let coordinate else {
            await monitor.remove(identifier)
            return
        }
        if let current = await monitor.record(for: identifier)?.condition as? CLMonitor.CircularGeographicCondition,
           current.center.latitude == coordinate.latitude,
           current.center.longitude == coordinate.longitude,
           current.radius == radius {
            return
        }
        let condition = CLMonitor.CircularGeographicCondition(
            center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
            radius: radius
        )
        await monitor.add(condition, identifier: identifier)
    }
}
