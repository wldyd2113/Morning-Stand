import Foundation

/// 현재 위치를 한 번 받는다. 구현(CoreLocation)은 Platform에 있다.
nonisolated protocol LocationProvider: Sendable {
    /// 권한이 아직 없으면 "앱을 사용하는 동안" 권한을 요청한다.
    /// - Throws: `AppError.locationDenied`, `AppError.locationUnavailable`
    func currentLocation() async throws -> LocationFix
}
