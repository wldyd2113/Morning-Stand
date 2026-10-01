import Foundation

/// 모든 API 호출이 지나가는 길: CacheStore(신선하면 바로 반환) → RateLimiter → APIClient.
/// 실패했는데 오래된 캐시가 있으면 `.cached`로 돌려줘서 화면이 "N분 전 기준"으로 계속 보이게 한다.
nonisolated struct CachedFetcher: Sendable {
    let cache: CacheStore
    let limiter: RateLimiter

    func fetch<Value: Sendable>(
        key: String,
        api: APIName,
        ttl: Duration,
        operation: @Sendable () async throws -> Value
    ) async throws -> Timestamped<Value> {
        let cached = await cache.lookup(key, as: Value.self, ttl: ttl)
        if case .fresh(let value, let savedAt) = cached {
            return Timestamped(value: value, fetchedAt: savedAt)
        }
        do {
            let value = try await performWithRetry(api: api, operation: operation)
            let savedAt = await cache.store(value, for: key)
            return Timestamped(value: value, fetchedAt: savedAt)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            let appError = AppError(error)
            if appError == .quotaExceeded { await limiter.exhaust(api) }
            if case .stale(let value, let savedAt) = cached {
                return Timestamped(value: value, fetchedAt: savedAt, freshness: .cached(appError == .offline ? .offline : .refreshFailed))
            }
            throw appError
        }
    }

    /// 타임아웃·서버 오류만 다시 시도한다. 매 시도마다 호출 한도를 1건씩 쓴다.
    private func performWithRetry<Value: Sendable>(api: APIName, operation: @Sendable () async throws -> Value) async throws -> Value {
        var attempt = 0
        while true {
            try await limiter.acquire(api)
            do {
                return try await operation()
            } catch let error as AppError where Self.isRetryable(error) && attempt < PolicyConstants.Network.maxRetryCount {
                attempt += 1
            }
        }
    }

    private static func isRetryable(_ error: AppError) -> Bool {
        switch error {
        case .timeout: true
        case .server(let code): code.hasPrefix("5")
        default: false
        }
    }
}
