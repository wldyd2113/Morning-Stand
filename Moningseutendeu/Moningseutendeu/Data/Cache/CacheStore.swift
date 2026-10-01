import Foundation

/// API 응답 메모리 캐시. 시각은 주입받은 `DateProvider`로만 판단한다.
/// TODO: 디스크 캐시와 진행 중 요청 합치기(in-flight coalescing)는 다음 단계에서 추가한다.
actor CacheStore {
    enum Lookup<Value: Sendable>: Sendable {
        case fresh(Value, savedAt: Date)
        case stale(Value, savedAt: Date)
        case miss
    }

    private struct Entry {
        let value: any Sendable
        let savedAt: Date
    }

    private var entries: [String: Entry] = [:]
    private let dateProvider: any DateProvider

    init(dateProvider: any DateProvider) {
        self.dateProvider = dateProvider
    }

    func lookup<Value: Sendable>(_ key: String, as type: Value.Type, ttl: Duration) -> Lookup<Value> {
        guard let entry = entries[key], let value = entry.value as? Value else { return .miss }
        let age = dateProvider.now.timeIntervalSince(entry.savedAt)
        if age <= ttl.timeInterval { return .fresh(value, savedAt: entry.savedAt) }
        if age <= PolicyConstants.CacheTTL.staleLimit.timeInterval { return .stale(value, savedAt: entry.savedAt) }
        return .miss
    }

    func store(_ value: some Sendable, for key: String) -> Date {
        let now = dateProvider.now
        entries[key] = Entry(value: value, savedAt: now)
        return now
    }
}

extension Duration {
    /// 초 단위 `TimeInterval`
    nonisolated var timeInterval: TimeInterval {
        let parts = components
        return TimeInterval(parts.seconds) + TimeInterval(parts.attoseconds) / 1e18
    }
}
