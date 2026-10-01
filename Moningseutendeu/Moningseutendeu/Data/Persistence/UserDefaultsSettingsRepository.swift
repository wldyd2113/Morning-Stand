import Foundation

/// 즐겨찾기 정류장·측정소 설정을 UserDefaults에 JSON으로 저장한다.
/// TODO: 즐겨찾기가 늘고 루틴과 엮이면 SwiftData(@ModelActor)로 옮긴다.
nonisolated struct UserDefaultsSettingsRepository: UserSettingsRepository {
    private var defaults: UserDefaults { .standard }

    func favoriteStops() -> [FavoriteStop] {
        guard let data = defaults.data(forKey: AppConstants.UserDefaultsKey.favoriteStops),
              let stops = try? JSONDecoder().decode([FavoriteStop].self, from: data) else { return [] }
        return stops
    }

    /// 같은 정류장이 있으면 바꾸고, 새 정류장은 맨 앞(기본 경로)에 넣는다
    func saveFavoriteStop(_ stop: FavoriteStop) {
        var stops = favoriteStops().filter { $0.id != stop.id }
        stops.insert(stop, at: 0)
        save(stops)
    }

    func removeFavoriteStop(id: String) {
        save(favoriteStops().filter { $0.id != id })
    }

    func airQualityStationName() -> String {
        defaults.string(forKey: AppConstants.UserDefaultsKey.airQualityStation) ?? PolicyConstants.AirQuality.defaultStationName
    }

    func setAirQualityStationName(_ name: String) {
        defaults.set(name, forKey: AppConstants.UserDefaultsKey.airQualityStation)
    }

    private func save(_ stops: [FavoriteStop]) {
        guard let data = try? JSONEncoder().encode(stops) else { return }
        defaults.set(data, forKey: AppConstants.UserDefaultsKey.favoriteStops)
    }
}
