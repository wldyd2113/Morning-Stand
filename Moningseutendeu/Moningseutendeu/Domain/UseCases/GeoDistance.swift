import Foundation

/// 두 위경도 사이의 거리 (하버사인). 주변 정류장 정렬과 도보 시간 어림에 쓴다.
nonisolated enum GeoDistance {
    private static let earthRadiusMeters = 6_371_000.0

    static func meters(from start: Coordinate, to end: Coordinate) -> Double {
        let degreeToRadian = Double.pi / 180
        let lat1 = start.latitude * degreeToRadian
        let lat2 = end.latitude * degreeToRadian
        let deltaLat = (end.latitude - start.latitude) * degreeToRadian
        let deltaLon = (end.longitude - start.longitude) * degreeToRadian
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
        return earthRadiusMeters * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}
