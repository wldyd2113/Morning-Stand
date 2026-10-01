import Foundation

/// 현재 날씨·대기질 저장소. 실패 시 캐시가 있으면 `.cached`로 돌려준다.
nonisolated protocol WeatherRepository: Sendable {
    func fetchCurrentWeather() async throws -> Timestamped<WeatherSummary>
}
