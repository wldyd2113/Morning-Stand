import Foundation

/// 받은 시각과 신선도를 함께 가진 값.
nonisolated struct Timestamped<Value: Sendable>: Sendable {
    var value: Value
    var fetchedAt: Date
    var freshness: Freshness

    init(value: Value, fetchedAt: Date, freshness: Freshness = .live) {
        self.value = value
        self.fetchedAt = fetchedAt
        self.freshness = freshness
    }
}

extension Timestamped: Equatable where Value: Equatable {}
