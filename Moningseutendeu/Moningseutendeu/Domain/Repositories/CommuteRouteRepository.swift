import Foundation

/// 즐겨찾기 경로와 요일별 루틴 저장소. 쓰기는 기기 안 저장소라 동기로 한다.
nonisolated protocol CommuteRouteRepository: Sendable {
    func fetchRoutes() async throws -> [CommuteRoute]
    func fetchRoutines() async throws -> [RoutineSetting]
    /// 같은 ID가 있으면 바꾸고, 없으면 뒤에 추가한다
    func saveRoute(_ route: CommuteRoute) throws
    func deleteRoute(id: String) throws
    func saveRoutine(_ routine: RoutineSetting) throws
}
