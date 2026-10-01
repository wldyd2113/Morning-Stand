import Foundation

/// 사용자 설정 저장소 (즐겨찾기 정류장, 미세먼지 측정소).
nonisolated protocol UserSettingsRepository: Sendable {
    func favoriteStops() -> [FavoriteStop]
    func saveFavoriteStop(_ stop: FavoriteStop)
    func removeFavoriteStop(id: String)
    func airQualityStationName() -> String
    func setAirQualityStationName(_ name: String)
}
