import CoreLocation
import Foundation

/// `CLLocationUpdate.liveUpdates()`에서 정확도가 충분한 첫 위치를 받고 끝낸다.
/// 권한이 없으면 `CLServiceSession`이 "앱을 사용하는 동안" 권한을 요청한다.
nonisolated struct CoreLocationProvider: LocationProvider {
    let clock: any Clock<Duration>

    func currentLocation() async throws -> LocationFix {
        let session = CLServiceSession(authorization: .whenInUse)
        defer { session.invalidate() }
        // 권한 요청 창이 떠 있는 동안은 사용자가 읽을 시간을 더 준다
        let isAskingPermission = CLLocationManager().authorizationStatus == .notDetermined
        let timeout = isAskingPermission ? PolicyConstants.Location.permissionPromptTimeout : PolicyConstants.Location.oneShotTimeout
        let clock = clock
        return try await withThrowingTaskGroup(of: LocationFix.self) { group in
            group.addTask { try await Self.firstAcceptableFix() }
            group.addTask {
                try await clock.sleep(for: timeout)
                throw AppError.locationUnavailable
            }
            defer { group.cancelAll() }
            guard let fix = try await group.next() else { throw AppError.locationUnavailable }
            return fix
        }
    }

    private static func firstAcceptableFix() async throws -> LocationFix {
        for try await update in CLLocationUpdate.liveUpdates() {
            if update.authorizationDenied || update.authorizationDeniedGlobally || update.authorizationRestricted {
                throw AppError.locationDenied
            }
            guard let location = update.location else { continue }
            // 대략적 위치는 기다려도 더 정확해지지 않으므로 바로 쓴다
            let isReduced = update.accuracyLimited
            guard isReduced || location.horizontalAccuracy <= PolicyConstants.Location.acceptableAccuracyMeters else { continue }
            return LocationFix(
                coordinate: Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
                horizontalAccuracyMeters: location.horizontalAccuracy,
                isAccuracyReduced: isReduced
            )
        }
        throw AppError.locationUnavailable
    }
}
