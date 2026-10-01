import Foundation

/// WGS84 위경도.
nonisolated struct Coordinate: Sendable, Equatable, Codable {
    var latitude: Double
    var longitude: Double
}
