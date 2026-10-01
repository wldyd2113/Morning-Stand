import Foundation

/// 기본 경로와 주변 노선의 도착 정보 저장소.
nonisolated protocol DepartureRepository: Sendable {
    func fetchDepartureBoard() async throws -> Timestamped<DepartureBoard>
}
