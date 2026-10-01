import Foundation

/// 대중교통 수단.
nonisolated enum TransportKind: String, Sendable, Equatable, Hashable, CaseIterable, Codable {
    case bus
    case subway
}
