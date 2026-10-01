import Foundation

/// 저장소가 돌려준 값이 방금 받은 것인지, 캐시에서 꺼낸 것인지.
nonisolated enum Freshness: Sendable, Equatable {
    case live
    case cached(StaleReason)
}
