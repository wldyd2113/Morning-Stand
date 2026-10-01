import Foundation

/// 값이 최신이 아닌 이유.
nonisolated enum StaleReason: Sendable, Equatable {
    /// 갱신 요청이 실패해 이전 값을 보여줌
    case refreshFailed
    /// 오프라인이라 이전 값을 보여줌
    case offline
}
