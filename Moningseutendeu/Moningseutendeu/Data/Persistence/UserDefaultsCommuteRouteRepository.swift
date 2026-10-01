import Foundation

/// 경로와 요일별 루틴을 UserDefaults에 JSON으로 저장한다.
/// TODO: 루틴·알림과 엮이면 SwiftData(@ModelActor)로 옮긴다.
nonisolated struct UserDefaultsCommuteRouteRepository: CommuteRouteRepository {
    private var defaults: UserDefaults { .standard }

    func fetchRoutes() async throws -> [CommuteRoute] { routes() }

    func fetchRoutines() async throws -> [RoutineSetting] { load([RoutineSetting].self, key: AppConstants.UserDefaultsKey.routines) ?? [] }

    func saveRoute(_ route: CommuteRoute) throws {
        var all = routes()
        if let index = all.firstIndex(where: { $0.id == route.id }) {
            all[index] = route
        } else {
            all.append(route)
        }
        try save(all, key: AppConstants.UserDefaultsKey.commuteRoutes)
    }

    func deleteRoute(id: String) throws {
        try save(routes().filter { $0.id != id }, key: AppConstants.UserDefaultsKey.commuteRoutes)
    }

    func saveRoutine(_ routine: RoutineSetting) throws {
        var all = load([RoutineSetting].self, key: AppConstants.UserDefaultsKey.routines) ?? []
        all.removeAll { $0.weekday == routine.weekday }
        all.append(routine)
        try save(all, key: AppConstants.UserDefaultsKey.routines)
    }

    private func routes() -> [CommuteRoute] {
        load([CommuteRoute].self, key: AppConstants.UserDefaultsKey.commuteRoutes) ?? []
    }

    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save(_ value: some Encodable, key: String) throws {
        do {
            defaults.set(try JSONEncoder().encode(value), forKey: key)
        } catch {
            throw AppError.decoding
        }
    }
}
