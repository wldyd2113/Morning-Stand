import Foundation
import Observation

/// 경로 편집에서 정류장 고르기: 즐겨찾기 바로 선택 + 이름 검색.
@MainActor @Observable
final class StopPickerViewModel: Identifiable {
    struct Row: Identifiable, Equatable {
        let id: String
        let name: String
        let detail: String
        let isFavorite: Bool
    }

    var query = ""
    var transport: TransportKind
    private(set) var results: SectionState<[TransitStop]> = .idle

    @ObservationIgnored private let favoriteStops: [FavoriteStop]
    @ObservationIgnored private let repository: any TransitStopRepository
    @ObservationIgnored private let dateProvider: any DateProvider
    @ObservationIgnored private let clock: any Clock<Duration>
    @ObservationIgnored private let onSelect: @MainActor (TransitStop) -> Void

    init(
        favorites: [FavoriteStop],
        initialKind: TransportKind,
        repository: any TransitStopRepository,
        dateProvider: any DateProvider,
        clock: any Clock<Duration>,
        onSelect: @escaping @MainActor (TransitStop) -> Void
    ) {
        self.favoriteStops = favorites
        self.transport = initialKind
        self.repository = repository
        self.dateProvider = dateProvider
        self.clock = clock
        self.onSelect = onSelect
    }

    var searchKey: String { "\(transport)-\(query)" }

    var isSearching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    /// 지금 고른 종류(버스/지하철)의 즐겨찾기
    var favoriteRows: [Row] {
        favoriteStops.filter { $0.kind == transport }.map { favorite in
            Row(id: favorite.id, name: favorite.name, detail: detail(id: favorite.id, kind: favorite.kind, direction: favorite.direction), isFavorite: true)
        }
    }

    var resultRows: [Row] {
        let favoriteIDs = Set(favoriteStops.map(\.id))
        return (results.value ?? []).map { stop in
            Row(id: stop.id, name: stop.name, detail: detail(id: stop.id, kind: stop.kind, direction: stop.direction), isFavorite: favoriteIDs.contains(stop.id))
        }
    }

    var isLoading: Bool {
        if case .loading = results { return true }
        return false
    }

    var message: String? {
        if case .failed(let error) = results { return error.userMessage }
        if isSearching, results.value?.isEmpty == true { return String(localized: "검색 결과가 없어요") }
        return nil
    }

    /// 입력이 멈추면 검색한다. 검색어가 바뀌면 `.task(id:)`가 이전 검색을 취소한다.
    func search() async {
        guard isSearching else {
            results = .idle
            return
        }
        do {
            try await clock.sleep(for: PolicyConstants.Search.debounceInterval)
        } catch {
            return
        }
        results = results.beginningLoad()
        do {
            let stops = try await repository.searchStops(query: query, kind: transport)
            guard !Task.isCancelled else { return }
            results = .loaded(stops, fetchedAt: dateProvider.now)
        } catch {
            guard !Task.isCancelled else { return }
            results = .failed(AppError(error))
        }
    }

    func select(_ id: String) {
        if let stop = results.value?.first(where: { $0.id == id }) {
            onSelect(stop)
        } else if let favorite = favoriteStops.first(where: { $0.id == id }) {
            onSelect(TransitStop(
                id: favorite.id, name: favorite.name, kind: favorite.kind, direction: favorite.direction,
                distanceMeters: nil, estimatedWalkMinutes: favorite.walkMinutes, routeNames: favorite.trackedRoutes,
                coordinate: favorite.coordinate
            ))
        }
    }

    private func detail(id: String, kind: TransportKind, direction: String) -> String {
        [kind == .bus ? id : nil, direction.isEmpty ? nil : direction].compactMap { $0 }.joined(separator: " · ")
    }
}
