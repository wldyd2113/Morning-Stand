import Foundation
import OSLog

/// 출근 기록 저장소. SwiftData 에러는 로그로 남기고 `AppError.persistence`로 바꿔서 내보낸다.
nonisolated struct SwiftDataCommuteHistoryRepository: CommuteHistoryRepository {
    let store: CommuteRecordStore

    func records(since start: Date) async throws -> [CommuteRecord] {
        try await mapError("조회") { try await store.records(since: start) }
    }

    func save(_ record: CommuteRecord) async throws {
        try await mapError("저장") { try await store.upsert(record) }
    }

    func delete(id: UUID) async throws {
        try await mapError("삭제") { try await store.delete(id: id) }
    }

    private func mapError<Value: Sendable>(_ action: String, _ operation: () async throws -> Value) async throws -> Value {
        do {
            return try await operation()
        } catch {
            Logger(subsystem: AppConstants.Logging.subsystem, category: AppConstants.Logging.historyCategory)
                .error("출근 기록 \(action, privacy: .public) 실패: \(String(describing: error), privacy: .public)")
            throw AppError.persistence
        }
    }
}
