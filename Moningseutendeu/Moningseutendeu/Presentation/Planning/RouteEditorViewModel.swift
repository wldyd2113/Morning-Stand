import Foundation
import Observation

/// 경로 추가·편집. 즐겨찾기 정류장과 노선을 고르고 구간 시간을 직접 입력한다.
@MainActor @Observable
final class RouteEditorViewModel: Identifiable {
    struct LegDraft: Identifiable, Equatable {
        let id = UUID()
        var stopID: String?
        var stopName: String = ""
        var kind: TransportKind = .bus
        var routeKey: String?
        var rideMinutes = PolicyConstants.RouteEditor.defaultRideMinutes
        /// 첫 구간은 집 → 정류장 도보, 이후는 환승 이동
        var accessMinutes: Int
    }

    struct OptionDraft: Identifiable, Equatable {
        let id = UUID()
        /// 편집 중인 기존 이동 방법의 ID (새로 만들면 nil)
        var existingID: String?
        var waitMinutes = PolicyConstants.RouteEditor.defaultWaitMinutes
        var legs: [LegDraft]
        var finalWalkMinutes = PolicyConstants.RouteEditor.defaultFinalWalkMinutes
    }

    var name: String
    var origin: String
    var destination: String
    var departure: Date
    private(set) var weekdays: Set<Weekday>
    var options: [OptionDraft]
    private(set) var favorites: [FavoriteStop] = []
    /// 정류장별 노선 목록. 키는 `routesKey(kind:stopID:)`
    private(set) var routeNamesByStop: [String: SectionState<[String]>] = [:]
    /// 열려 있는 정류장 고르기 화면
    private(set) var stopPicker: StopPickerViewModel?
    private(set) var saveErrorMessage: String?

    let isEditing: Bool
    @ObservationIgnored private let routeID: String
    @ObservationIgnored private let repository: any CommuteRouteRepository
    @ObservationIgnored private let settings: any UserSettingsRepository
    @ObservationIgnored private let stopRepository: any TransitStopRepository
    @ObservationIgnored private let dateProvider: any DateProvider
    @ObservationIgnored private let clock: any Clock<Duration>
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private let onFinish: @MainActor () -> Void
    /// 고른 정류장의 원래 정보 (검색 결과에 노선이 들어 있으면 다시 부르지 않는다)
    @ObservationIgnored private var knownStops: [String: TransitStop] = [:]

    init(
        route: CommuteRoute?,
        repository: any CommuteRouteRepository,
        settings: any UserSettingsRepository,
        stopRepository: any TransitStopRepository,
        dateProvider: any DateProvider,
        clock: any Clock<Duration>,
        calendar: Calendar = .seoul,
        onFinish: @escaping @MainActor () -> Void
    ) {
        self.clock = clock
        self.repository = repository
        self.settings = settings
        self.stopRepository = stopRepository
        self.dateProvider = dateProvider
        self.calendar = calendar
        self.onFinish = onFinish
        isEditing = route != nil
        routeID = route?.id ?? UUID().uuidString
        name = route?.name ?? ""
        origin = route?.origin ?? ""
        destination = route?.destination ?? ""
        let time = route?.departure ?? TimeOfDay(hour: PolicyConstants.RouteEditor.defaultDepartureHour, minute: 0)
        departure = time.date(on: dateProvider.now, calendar: calendar)
        weekdays = Set(route?.weekdays ?? [.monday, .tuesday, .wednesday, .thursday, .friday])
        let drafts = route?.options.compactMap(Self.draft(from:)) ?? []
        options = drafts.isEmpty ? [Self.emptyOption()] : drafts
    }

    var title: String { isEditing ? String(localized: "경로 편집") : String(localized: "경로 추가") }

    // MARK: - 불러오기

    func load() async {
        favorites = settings.favoriteStops()
    }

    /// 고른 정류장에 서는 노선 목록. 즐겨찾기에서 고른 노선을 앞에 둔다.
    /// 실패하면 즐겨찾기에 저장해 둔 노선으로 대신한다.
    func loadRoutes(for leg: LegDraft) async {
        guard let stopID = leg.stopID else { return }
        let key = Self.routesKey(kind: leg.kind, stopID: stopID)
        guard routeNamesByStop[key]?.value == nil else { return }
        let favorite = favorites.first { $0.id == stopID && $0.kind == leg.kind }
        let tracked = favorite?.trackedRoutes ?? []
        // 검색 결과의 노선은 그대로 쓰고, 비어 있으면 저장소가 정류장 도착 정보로 노선을 불러온다
        let stop = knownStops[key] ?? TransitStop(
            id: stopID, name: leg.stopName, kind: leg.kind, direction: favorite?.direction ?? "",
            distanceMeters: nil, estimatedWalkMinutes: favorite?.walkMinutes ?? PolicyConstants.Walking.defaultMinutes, routeNames: []
        )
        routeNamesByStop[key] = .loading
        do {
            let fetched = try await stopRepository.routeNames(for: stop)
            guard !Task.isCancelled else { return }
            let first = tracked.filter(fetched.contains)
            routeNamesByStop[key] = .loaded(first + fetched.filter { !first.contains($0) }, fetchedAt: dateProvider.now)
        } catch {
            guard !Task.isCancelled else { return }
            routeNamesByStop[key] = tracked.isEmpty ? .failed(AppError(error)) : .loaded(tracked, fetchedAt: dateProvider.now)
        }
    }

    func routeNames(for leg: LegDraft) -> [String] {
        guard let stopID = leg.stopID else { return [] }
        let names = routeNamesByStop[Self.routesKey(kind: leg.kind, stopID: stopID)]?.value ?? []
        // 저장된 노선이 목록에 없어도(운행 시간 외 등) 선택이 풀리지 않게 남겨 둔다
        if let current = leg.routeKey, !names.contains(current) { return [current] + names }
        return names
    }

    func routesMessage(for leg: LegDraft) -> String? {
        guard let stopID = leg.stopID else { return nil }
        switch routeNamesByStop[Self.routesKey(kind: leg.kind, stopID: stopID)] {
        case .loading: return String(localized: "노선을 불러오는 중")
        case .failed(let error): return error.userMessage
        default: return nil
        }
    }

    // MARK: - 편집

    func toggleWeekday(_ weekday: Weekday) {
        if weekdays.contains(weekday) {
            weekdays.remove(weekday)
        } else {
            weekdays.insert(weekday)
        }
    }

    func isSelected(_ weekday: Weekday) -> Bool { weekdays.contains(weekday) }

    // MARK: - 정류장 고르기

    func openStopPicker(optionID: OptionDraft.ID, legID: LegDraft.ID) {
        guard let (optionIndex, legIndex) = indices(optionID: optionID, legID: legID) else { return }
        stopPicker = StopPickerViewModel(
            favorites: favorites,
            initialKind: options[optionIndex].legs[legIndex].kind,
            repository: stopRepository,
            dateProvider: dateProvider,
            clock: clock
        ) { [weak self] stop in
            self?.selectStop(stop, optionID: optionID, legID: legID)
            self?.closeStopPicker()
        }
    }

    func closeStopPicker() {
        stopPicker = nil
    }

    /// 정류장을 바꾸면 노선을 다시 고르게 하고, 첫 구간이면 도보 시간(즐겨찾기 값 우선)을 넣는다.
    func selectStop(_ stop: TransitStop, optionID: OptionDraft.ID, legID: LegDraft.ID) {
        guard let (optionIndex, legIndex) = indices(optionID: optionID, legID: legID) else { return }
        var leg = options[optionIndex].legs[legIndex]
        guard leg.stopID != stop.id || leg.kind != stop.kind else { return }
        let favorite = favorites.first { $0.id == stop.id && $0.kind == stop.kind }
        knownStops[Self.routesKey(kind: stop.kind, stopID: stop.id)] = stop
        leg.stopID = stop.id
        leg.stopName = stop.name
        leg.kind = stop.kind
        leg.routeKey = favorite?.trackedRoutes.first
        if legIndex == 0 { leg.accessMinutes = favorite?.walkMinutes ?? stop.estimatedWalkMinutes }
        options[optionIndex].legs[legIndex] = leg
    }

    /// "연신내역.로데오거리 (12184)", 지하철은 역 이름만
    func stopTitle(for leg: LegDraft) -> String? {
        guard let stopID = leg.stopID else { return nil }
        return leg.kind == .bus ? "\(leg.stopName) (\(stopID))" : leg.stopName
    }

    private static func routesKey(kind: TransportKind, stopID: String) -> String {
        "\(kind.rawValue)-\(stopID)"
    }

    func addOption() {
        options.append(Self.emptyOption())
    }

    func removeOption(_ optionID: OptionDraft.ID) {
        guard options.count > 1 else { return }
        options.removeAll { $0.id == optionID }
    }

    func canAddTransfer(_ optionID: OptionDraft.ID) -> Bool {
        (options.first { $0.id == optionID }?.legs.count ?? 0) < PolicyConstants.RouteEditor.maximumLegs
    }

    func addTransfer(_ optionID: OptionDraft.ID) {
        guard canAddTransfer(optionID), let index = options.firstIndex(where: { $0.id == optionID }) else { return }
        options[index].legs.append(LegDraft(accessMinutes: PolicyConstants.RouteEditor.defaultTransferMinutes))
    }

    func removeLeg(optionID: OptionDraft.ID, legID: LegDraft.ID) {
        guard let (optionIndex, legIndex) = indices(optionID: optionID, legID: legID), legIndex > 0 else { return }
        options[optionIndex].legs.remove(at: legIndex)
    }

    // MARK: - 검증·저장

    /// 저장할 수 없는 이유. 저장할 수 있으면 nil
    var validationMessage: String? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty { return String(localized: "경로 이름을 입력하세요") }
        if weekdays.isEmpty { return String(localized: "출발 요일을 하나 이상 고르세요") }
        let incomplete = options.contains { option in option.legs.contains { $0.stopID == nil || $0.routeKey == nil } }
        if incomplete { return String(localized: "모든 구간의 정류장과 노선을 고르세요") }
        return nil
    }

    var canSave: Bool { validationMessage == nil }

    /// "총 41분 · 08:51 도착"
    func summary(for option: OptionDraft) -> String {
        guard let plan = plan(from: option) else { return String(localized: "정류장과 노선을 고르면 소요 시간을 계산해요") }
        let total = RouteOptionBuilder.option(id: "", plan: plan).totalMinutes
        let arrival = TimeOfDay(date: departure, calendar: calendar).adding(minutes: total).text
        return String(localized: "총 \(total)분 · \(arrival) 도착")
    }

    func save() {
        guard canSave else { return }
        let route = CommuteRoute(
            id: routeID,
            name: name.trimmingCharacters(in: .whitespaces),
            origin: origin.trimmingCharacters(in: .whitespaces),
            destination: destination.trimmingCharacters(in: .whitespaces),
            departure: TimeOfDay(date: departure, calendar: calendar),
            weekdays: Weekday.displayOrder.filter(weekdays.contains),
            options: options.compactMap { draft in
                plan(from: draft).map { RouteOptionBuilder.option(id: draft.existingID ?? UUID().uuidString, plan: $0) }
            }
        )
        do {
            try repository.saveRoute(route)
            onFinish()
        } catch {
            saveErrorMessage = AppError(error).userMessage
        }
    }

    func delete() {
        do {
            try repository.deleteRoute(id: routeID)
            onFinish()
        } catch {
            saveErrorMessage = AppError(error).userMessage
        }
    }

    func cancel() {
        onFinish()
    }

    // MARK: - 변환

    private func plan(from draft: OptionDraft) -> RoutePlan? {
        var legs: [RouteLeg] = []
        for leg in draft.legs {
            guard let stopID = leg.stopID, let routeKey = leg.routeKey else { return nil }
            legs.append(RouteLeg(stopID: stopID, stopName: leg.stopName, kind: leg.kind, routeKey: routeKey, rideMinutes: leg.rideMinutes, accessMinutes: leg.accessMinutes))
        }
        return RoutePlan(waitMinutes: draft.waitMinutes, legs: legs, finalWalkMinutes: draft.finalWalkMinutes)
    }

    private static func draft(from option: RouteOption) -> OptionDraft? {
        guard let plan = option.plan else { return nil }
        return OptionDraft(
            existingID: option.id,
            waitMinutes: plan.waitMinutes,
            legs: plan.legs.map { leg in
                LegDraft(stopID: leg.stopID, stopName: leg.stopName, kind: leg.kind, routeKey: leg.routeKey, rideMinutes: leg.rideMinutes, accessMinutes: leg.accessMinutes)
            },
            finalWalkMinutes: plan.finalWalkMinutes
        )
    }

    private static func emptyOption() -> OptionDraft {
        OptionDraft(legs: [LegDraft(accessMinutes: PolicyConstants.Walking.defaultMinutes)])
    }

    private func indices(optionID: OptionDraft.ID, legID: LegDraft.ID) -> (Int, Int)? {
        guard let optionIndex = options.firstIndex(where: { $0.id == optionID }),
              let legIndex = options[optionIndex].legs.firstIndex(where: { $0.id == legID }) else { return nil }
        return (optionIndex, legIndex)
    }
}
