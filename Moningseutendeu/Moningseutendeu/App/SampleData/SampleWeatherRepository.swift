import Foundation

/// 공공 API 연동 전까지 쓰는 날씨 샘플 저장소. 값은 디자인 시안과 같다.
nonisolated struct SampleWeatherRepository: WeatherRepository {
    let scenario: StandScenario
    let dateProvider: any DateProvider
    let clock: any Clock<Duration>
    var calendar: Calendar = .seoul

    static let morning = WeatherSummary(temperatureCelsius: 14, condition: .partlyCloudy, highCelsius: 21, lowCelsius: 12, pm10: .moderate, pm25: .bad, rainStartHour: 18)
    static let lateNight = WeatherSummary(temperatureCelsius: 11, condition: .clear, highCelsius: 21, lowCelsius: 10, pm10: .good, pm25: .moderate, rainStartHour: nil)

    func fetchCurrentWeather() async throws -> Timestamped<WeatherSummary> {
        let now = dateProvider.now
        switch scenario {
        case .loading:
            try await clock.sleep(for: .seconds(60 * 60))
            throw AppError.timeout
        case .weatherStale:
            return Timestamped(value: Self.morning, fetchedAt: minutes(-25, from: now), freshness: .cached(.refreshFailed))
        case .offline:
            return Timestamped(value: Self.morning, fetchedAt: minutes(-24, from: now), freshness: .cached(.offline))
        case .ended:
            return Timestamped(value: Self.lateNight, fetchedAt: now)
        case .relaxed, .soon, .now, .missed:
            return Timestamped(value: Self.morning, fetchedAt: now)
        }
    }

    private func minutes(_ value: Int, from date: Date) -> Date {
        calendar.date(byAdding: .minute, value: value, to: date) ?? date
    }
}
