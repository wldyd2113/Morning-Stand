import Foundation
import Synchronization

/// Preview·UI 테스트용 설정 저장소. 앱을 끄면 사라진다.
nonisolated final class InMemorySettingsRepository: UserSettingsRepository {
    private struct State {
        var favorites: [FavoriteStop]
        var stationName: String
    }

    // Mutex로 보호하므로 여러 Task에서 안전하게 읽고 쓴다
    private let state: Mutex<State>

    init(favorites: [FavoriteStop] = [], stationName: String = PolicyConstants.AirQuality.defaultStationName) {
        state = Mutex(State(favorites: favorites, stationName: stationName))
    }

    func favoriteStops() -> [FavoriteStop] { state.withLock { $0.favorites } }

    func saveFavoriteStop(_ stop: FavoriteStop) {
        state.withLock { state in
            state.favorites.removeAll { $0.id == stop.id }
            state.favorites.insert(stop, at: 0)
        }
    }

    func removeFavoriteStop(id: String) {
        state.withLock { $0.favorites.removeAll { $0.id == id } }
    }

    func airQualityStationName() -> String { state.withLock { $0.stationName } }

    func setAirQualityStationName(_ name: String) { state.withLock { $0.stationName = name } }
}
