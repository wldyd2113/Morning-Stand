import Foundation
import Observation

/// 펼침 플래닝 화면 상태: 경로 선택, 요일별 루틴 편집.
@MainActor @Observable
final class PlanningViewModel {
    private(set) var routes: SectionState<[CommuteRoute]> = .idle
    private(set) var routines: [Weekday: RoutineSetting] = [:]
    private(set) var selectedRouteID: String?
    private(set) var selectedWeekday: Weekday
    /// 열려 있는 경로 편집 시트
    private(set) var editor: RouteEditorViewModel?
    /// 편집이 끝나면 늘려서 View의 `.task(id:)`가 다시 불러오게 한다
    private(set) var reloadToken = 0
    private(set) var saveErrorMessage: String?

    @ObservationIgnored private let repository: any CommuteRouteRepository
    @ObservationIgnored private let makeEditor: @MainActor (CommuteRoute?, @escaping @MainActor () -> Void) -> RouteEditorViewModel
    @ObservationIgnored private let dateProvider: any DateProvider
    @ObservationIgnored private let calendar: Calendar

    init(
        repository: any CommuteRouteRepository,
        dateProvider: any DateProvider,
        calendar: Calendar = .seoul,
        makeEditor: @escaping @MainActor (CommuteRoute?, @escaping @MainActor () -> Void) -> RouteEditorViewModel
    ) {
        self.repository = repository
        self.makeEditor = makeEditor
        self.dateProvider = dateProvider
        self.calendar = calendar
        let today = calendar.component(.weekday, from: dateProvider.now)
        self.selectedWeekday = Weekday(rawValue: today) ?? .monday
    }

    var display: PlanningDisplayModel {
        PlanningDisplayMapper.make(
            routes: routes,
            selectedRouteID: selectedRouteID,
            routines: routines,
            selectedWeekday: selectedWeekday,
            now: dateProvider.now,
            calendar: calendar
        )
    }

    func load() async {
        routes = routes.beginningLoad()
        do {
            let fetchedRoutes = try await repository.fetchRoutes()
            let fetchedRoutines = try await repository.fetchRoutines()
            routes = .loaded(fetchedRoutes, fetchedAt: dateProvider.now)
            routines = Dictionary(fetchedRoutines.map { ($0.weekday, $0) }, uniquingKeysWith: { _, latest in latest })
            if selectedRouteID == nil || !fetchedRoutes.contains(where: { $0.id == selectedRouteID }) {
                selectedRouteID = fetchedRoutes.first?.id
            }
        } catch {
            routes = routes.resolved(with: .failure(AppError(error)))
        }
    }

    func selectRoute(id: String) {
        selectedRouteID = id
    }

    func selectWeekday(_ weekday: Weekday) {
        selectedWeekday = weekday
    }

    /// 선택한 요일의 루틴을 켜고 끄고 저장한다.
    func toggleSelectedWeekday() {
        var setting = routines[selectedWeekday] ?? RoutineSetting(weekday: selectedWeekday, isEnabled: false)
        setting.isEnabled.toggle()
        routines[selectedWeekday] = setting
        do {
            try repository.saveRoutine(setting)
            saveErrorMessage = nil
        } catch {
            saveErrorMessage = AppError(error).userMessage
        }
    }

    // MARK: - 경로 편집

    func addRoute() {
        editor = makeEditor(nil) { [weak self] in self?.finishEditing() }
    }

    func editSelectedRoute() {
        guard let route = routes.value?.first(where: { $0.id == selectedRouteID }) ?? routes.value?.first else { return }
        editor = makeEditor(route) { [weak self] in self?.finishEditing() }
    }

    /// 저장·삭제·취소 후 시트를 닫고 목록을 다시 불러온다.
    func finishEditing() {
        editor = nil
        reloadToken += 1
    }
}
