import Foundation

/// 출근 기록 저장소.
nonisolated protocol CommuteHistoryRepository: Sendable {
    /// `start` 이후에 집을 나선 기록. 집을 나선 시각 오름차순
    func records(since start: Date) async throws -> [CommuteRecord]
    /// 같은 ID가 있으면 바꾸고, 없으면 추가한다
    func save(_ record: CommuteRecord) async throws
    func delete(id: UUID) async throws
}
