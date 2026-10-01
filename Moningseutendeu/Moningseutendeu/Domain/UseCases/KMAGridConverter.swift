import Foundation

/// 위경도 → 기상청 격자(nx, ny) 변환 (Lambert Conformal Conic). 상수는 기상청 명세 값.
nonisolated enum KMAGridConverter {
    private static let earthRadiusKm = 6371.00877
    private static let gridSpacingKm = 5.0
    private static let standardLatitude1 = 30.0
    private static let standardLatitude2 = 60.0
    private static let originLongitude = 126.0
    private static let originLatitude = 38.0
    private static let originX = 43.0
    private static let originY = 136.0

    static func gridPoint(for coordinate: Coordinate) -> GridPoint {
        let degreeToRadian = Double.pi / 180
        let re = earthRadiusKm / gridSpacingKm
        let slat1 = standardLatitude1 * degreeToRadian
        let slat2 = standardLatitude2 * degreeToRadian
        let olon = originLongitude * degreeToRadian
        let olat = originLatitude * degreeToRadian

        var sn = tan(Double.pi * 0.25 + slat2 * 0.5) / tan(Double.pi * 0.25 + slat1 * 0.5)
        sn = log(cos(slat1) / cos(slat2)) / log(sn)
        var sf = tan(Double.pi * 0.25 + slat1 * 0.5)
        sf = pow(sf, sn) * cos(slat1) / sn
        var ro = tan(Double.pi * 0.25 + olat * 0.5)
        ro = re * sf / pow(ro, sn)

        var ra = tan(Double.pi * 0.25 + coordinate.latitude * degreeToRadian * 0.5)
        ra = re * sf / pow(ra, sn)
        var theta = coordinate.longitude * degreeToRadian - olon
        if theta > Double.pi { theta -= 2 * Double.pi }
        if theta < -Double.pi { theta += 2 * Double.pi }
        theta *= sn

        let x = ra * sin(theta) + originX
        let y = ro - ra * cos(theta) + originY
        return GridPoint(nx: Int(floor(x + 0.5)), ny: Int(floor(y + 0.5)))
    }
}
