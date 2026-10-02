import CoreLocation
import Foundation
import MapKit
import OSLog

/// MapKit 도보 경로 예상 시간. 호출 제한이 있어서 즐겨찾기에 넣을 정류장을 고를 때만 부른다.
nonisolated struct MapKitWalkingRouteService: WalkingRouteService {
    func walkingSeconds(from start: Coordinate, to end: Coordinate) async throws -> TimeInterval {
        let request = MKDirections.Request()
        request.source = MKMapItem(location: CLLocation(latitude: start.latitude, longitude: start.longitude), address: nil)
        request.destination = MKMapItem(location: CLLocation(latitude: end.latitude, longitude: end.longitude), address: nil)
        request.transportType = .walking
        do {
            return try await MKDirections(request: request).calculateETA().expectedTravelTime
        } catch {
            Logger(subsystem: AppConstants.Logging.subsystem, category: AppConstants.Logging.locationCategory)
                .error("도보 경로 계산 실패: \(error.localizedDescription, privacy: .public)")
            throw AppError.routeUnavailable
        }
    }
}
