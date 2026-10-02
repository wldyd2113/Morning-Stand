import Foundation
import Synchronization

/// Preview·UI 테스트용 설정 저장소. 앱을 끄면 사라진다.
nonisolated final class InMemorySettingsRepository: UserSettingsRepository {
    private struct State {
        var favorites: [FavoriteStop]
        var stationName: String
        var home: Coordinate?
        var isAutomationEnabled = false
        var presence: [CommuteRegion: RegionPresence] = [:]
    }

    // Mutex로 보호하므로 여러 Task에서 안전하게 읽고 쓴다
    private let state: Mutex<State>

    init(favorites: [FavoriteStop] = [], stationName: String = PolicyConstants.AirQuality.defaultStationName, home: Coordinate? = nil) {
        state = Mutex(State(favorites: favorites, stationName: stationName, home: home))
    }

    func favoriteStops() -> [FavoriteStop] { state.withLock { $0.favorites } }

    func saveFavoriteStop(_ stop: FavoriteStop) {
        state.withLock { state in
            state.favorites.removeAll { $0.id == stop.id }
            state.favorites.insert(stop, at: 0)
        }
    }

    func setFavoriteStops(_ stops: [FavoriteStop]) {
        state.withLock { $0.favorites = stops }
    }

    func removeFavoriteStop(id: String) {
        state.withLock { $0.favorites.removeAll { $0.id == id } }
    }

    func airQualityStationName() -> String { state.withLock { $0.stationName } }

    func setAirQualityStationName(_ name: String) { state.withLock { $0.stationName = name } }

    func homeLocation() -> Coordinate? { state.withLock { $0.home } }

    func setHomeLocation(_ coordinate: Coordinate?) { state.withLock { $0.home = coordinate } }

    func isCommuteAutomationEnabled() -> Bool { state.withLock { $0.isAutomationEnabled } }

    func setCommuteAutomationEnabled(_ isEnabled: Bool) { state.withLock { $0.isAutomationEnabled = isEnabled } }

    func lastRegionPresence(_ region: CommuteRegion) -> RegionPresence? { state.withLock { $0.presence[region] } }

    func setLastRegionPresence(_ presence: RegionPresence?, for region: CommuteRegion) {
        state.withLock { $0.presence[region] = presence }
    }
}
