import CoreLocation

extension Coordinate {
    /// 지도(MapKit)에 넘길 좌표. Domain은 CoreLocation을 모르므로 View 계층에서만 바꾼다.
    var locationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
