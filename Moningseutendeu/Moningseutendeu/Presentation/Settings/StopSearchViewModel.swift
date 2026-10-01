import Foundation
import Observation

/// 정류장 검색, 도보 시간, 알림 받을 노선 선택, 즐겨찾기 저장.
@MainActor @Observable
final class StopSearchViewModel {
    var query: String
    var transport: TransportKind = .bus
    private(set) var results: SectionState<[TransitStop]> = .idle
    private(set) var selectedStopID: String?
    private(set) var walkMinutes: Int = PolicyConstants.Walking.defaultMinutes
    private(set) var trackedRoutes: Set<String> = []
    private(set) var favoriteStopIDs: Set<String>
    /// 검색 결과에 노선이 없는 정류장은 고를 때 노선을 따로 불러온다
    private(set) var loadedRoutes: [String: SectionState<[String]>] = [:]

    @ObservationIgnored private let repository: any TransitStopRepository
    @ObservationIgnored private let settings: any UserSettingsRepository
    @ObservationIgnored private let dateProvider: any DateProvider
    @ObservationIgnored private let clock: any Clock<Duration>

    init(
        repository: any TransitStopRepository,
        settings: any UserSettingsRepository,
        dateProvider: any DateProvider,
        clock: any Clock<Duration>,
        initialQuery: String = ""
    ) {
        self.repository = repository
        self.settings = settings
        self.dateProvider = dateProvider
        self.clock = clock
        self.query = initialQuery
        self.favoriteStopIDs = Set(settings.favoriteStops().map(\.id))
    }

    /// 검색 조건. View가 `.task(id:)`에 넘겨서 조건이 바뀌면 이전 검색을 취소하게 한다.
    var searchKey: String { "\(transport)-\(query)" }

    private var selectedStop: TransitStop? {
        results.value?.first { $0.id == selectedStopID }
    }

    var display: StopSearchDisplayModel {
        let stops = results.value ?? []
        let isLoading: Bool
        if case .loading = results { isLoading = true } else { isLoading = false }

        var emptyMessage: String?
        if case .failed(let error) = results {
            emptyMessage = error.userMessage
        } else if results.value?.isEmpty == true {
            emptyMessage = query.trimmingCharacters(in: .whitespaces).isEmpty
                ? String(localized: "정류장이나 역 이름을 입력하세요")
                : String(localized: "검색 결과가 없어요")
        }

        return StopSearchDisplayModel(
            rows: stops.map { stop in
                StopSearchDisplayModel.Row(
                    id: stop.id,
                    name: stop.name,
                    detail: detailText(stop, includeDistance: true),
                    isSelected: stop.id == selectedStopID,
                    isFavorite: favoriteStopIDs.contains(stop.id)
                )
            },
            isLoading: isLoading,
            emptyMessage: emptyMessage,
            selection: selectedStop.map(selection(for:))
        )
    }

    private func detailText(_ stop: TransitStop, includeDistance: Bool) -> String {
        var parts = [stop.kind == .bus ? stop.id : nil, stop.direction.isEmpty ? nil : stop.direction]
        if includeDistance, let meters = stop.distanceMeters {
            parts.append(DisplayFormatter.distanceText(meters: meters))
        }
        return parts.compactMap { $0 }.joined(separator: " · ")
    }

    private func routeNames(for stop: TransitStop) -> [String] {
        stop.routeNames.isEmpty ? (loadedRoutes[stop.id]?.value ?? []) : stop.routeNames
    }

    private func selection(for stop: TransitStop) -> StopSearchDisplayModel.Selection {
        let isFavorite = favoriteStopIDs.contains(stop.id)
        let walkHint = stop.distanceMeters == nil
            ? String(localized: "집에서 정류장까지 실제로 걸리는 시간으로 맞춰 주세요")
            : String(localized: "지도 예상 \(stop.estimatedWalkMinutes)분 · 엘리베이터 대기까지 넣어 두면 좋아요")
        var routesMessage: String?
        switch loadedRoutes[stop.id] {
        case .loading: routesMessage = String(localized: "노선을 불러오는 중")
        case .failed(let error): routesMessage = error.userMessage
        default: break
        }
        return StopSearchDisplayModel.Selection(
            name: stop.name,
            detail: detailText(stop, includeDistance: false),
            walkMinutesText: "\(walkMinutes)",
            walkHint: walkHint,
            canDecreaseWalk: walkMinutes > PolicyConstants.Walking.minimumMinutes,
            canIncreaseWalk: walkMinutes < PolicyConstants.Walking.maximumMinutes,
            routes: routeNames(for: stop).map { StopSearchDisplayModel.RouteChip(name: $0, isTracked: trackedRoutes.contains($0)) },
            routesMessage: routesMessage,
            isFavorite: isFavorite,
            actionTitle: isFavorite ? String(localized: "즐겨찾기 저장됨 · 다시 저장") : String(localized: "즐겨찾기에 추가")
        )
    }

    /// 입력이 잠시 멈추면 검색한다. 새 검색이 시작되면 `.task(id:)`가 이전 호출을 취소한다.
    func search() async {
        if results.value != nil {
            do {
                try await clock.sleep(for: PolicyConstants.Search.debounceInterval)
            } catch {
                return
            }
        }
        results = results.beginningLoad()
        do {
            let stops = try await repository.searchStops(query: query, kind: transport)
            guard !Task.isCancelled else { return }
            results = .loaded(stops, fetchedAt: dateProvider.now)
            // 검색 결과에서 사라진 정류장은 선택을 풀어 시트를 닫는다
            if !stops.contains(where: { $0.id == selectedStopID }) {
                selectedStopID = nil
            }
        } catch {
            guard !Task.isCancelled else { return }
            results = .failed(AppError(error))
        }
    }

    /// 고른 정류장의 노선이 비어 있으면 불러온다. View의 `.task(id: selectedStopID)`에서 부른다.
    func loadRoutesForSelection() async {
        guard let stop = selectedStop, stop.routeNames.isEmpty, loadedRoutes[stop.id]?.value == nil else { return }
        loadedRoutes[stop.id] = .loading
        do {
            let routes = try await repository.routeNames(for: stop)
            guard !Task.isCancelled else { return }
            loadedRoutes[stop.id] = .loaded(routes, fetchedAt: dateProvider.now)
            if trackedRoutes.isEmpty, let first = routes.first, selectedStopID == stop.id {
                trackedRoutes = [first]
            }
        } catch {
            guard !Task.isCancelled else { return }
            loadedRoutes[stop.id] = .failed(AppError(error))
        }
    }

    /// 정류장을 탭했을 때. 이미 선택한 정류장을 다시 탭하면 선택을 푼다(시트 닫힘).
    func toggleSelection(stopID: String) {
        if selectedStopID == stopID {
            clearSelection()
        } else {
            select(stopID: stopID)
        }
    }

    /// 상세 시트를 닫는다.
    func clearSelection() {
        selectedStopID = nil
    }

    /// 정류장을 고르면 저장된 즐겨찾기 값, 없으면 예상 도보 시간과 첫 노선으로 채운다.
    func select(stopID: String) {
        guard let stop = results.value?.first(where: { $0.id == stopID }) else { return }
        selectedStopID = stop.id
        if let saved = settings.favoriteStops().first(where: { $0.id == stop.id }) {
            walkMinutes = clampedWalk(saved.walkMinutes)
            trackedRoutes = Set(saved.trackedRoutes)
        } else {
            walkMinutes = clampedWalk(stop.estimatedWalkMinutes)
            trackedRoutes = Set(routeNames(for: stop).prefix(1))
        }
    }

    /// 별을 누르면 바로 저장하거나 뺀다.
    func toggleFavorite(stopID: String) {
        if favoriteStopIDs.contains(stopID) {
            settings.removeFavoriteStop(id: stopID)
            favoriteStopIDs.remove(stopID)
        } else if let stop = results.value?.first(where: { $0.id == stopID }) {
            let isSelected = stopID == selectedStopID
            save(stop, walk: isSelected ? walkMinutes : stop.estimatedWalkMinutes, tracked: isSelected ? Array(trackedRoutes) : Array(routeNames(for: stop).prefix(1)))
        }
    }

    func decreaseWalk() {
        walkMinutes = clampedWalk(walkMinutes - 1)
    }

    func increaseWalk() {
        walkMinutes = clampedWalk(walkMinutes + 1)
    }

    func toggleRoute(_ name: String) {
        if trackedRoutes.contains(name) {
            trackedRoutes.remove(name)
        } else {
            trackedRoutes.insert(name)
        }
    }

    /// 고른 정류장을 기본 경로(첫 번째 즐겨찾기)로 저장한다. 스탠드 화면이 이 정류장을 보여준다.
    func addSelectedToFavorites() {
        guard let stop = selectedStop else { return }
        save(stop, walk: walkMinutes, tracked: routeNames(for: stop).filter(trackedRoutes.contains))
    }

    private func save(_ stop: TransitStop, walk: Int, tracked: [String]) {
        settings.saveFavoriteStop(FavoriteStop(
            id: stop.id,
            kind: stop.kind,
            name: stop.name,
            direction: stop.direction,
            walkMinutes: walk,
            trackedRoutes: tracked,
            coordinate: stop.coordinate
        ))
        favoriteStopIDs.insert(stop.id)
    }

    private func clampedWalk(_ minutes: Int) -> Int {
        min(max(minutes, PolicyConstants.Walking.minimumMinutes), PolicyConstants.Walking.maximumMinutes)
    }
}
