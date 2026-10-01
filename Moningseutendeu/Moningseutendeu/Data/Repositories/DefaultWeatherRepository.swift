import Foundation

/// 기상청(현재·예보) + 에어코리아(미세먼지)를 합쳐 현재 날씨를 만든다.
/// 위치는 첫 번째 즐겨찾기 정류장 좌표, 없으면 기본 좌표(서울시청). 미세먼지가 실패해도 날씨는 보여준다.
nonisolated struct DefaultWeatherRepository: WeatherRepository {
    let requester: PublicAPIRequester
    let fetcher: CachedFetcher
    let settings: any UserSettingsRepository
    let dateProvider: any DateProvider
    var calendar: Calendar = .seoul

    func fetchCurrentWeather() async throws -> Timestamped<WeatherSummary> {
        let now = dateProvider.now
        let coordinate = settings.favoriteStops().first?.coordinate ?? PolicyConstants.DefaultLocation.coordinate
        let grid = KMAGridConverter.gridPoint(for: coordinate)
        let stationName = settings.airQualityStationName()

        async let nowcast = kma(APIConstants.KMA.ultraShortNowcastPath, base: .nowcast(at: now, calendar: calendar), grid: grid, pageSize: PolicyConstants.KMA.nowcastPageSize, ttl: PolicyConstants.CacheTTL.weatherNowcast)
        async let forecast = kma(APIConstants.KMA.villageForecastPath, base: .villageForecast(at: now, calendar: calendar), grid: grid, pageSize: PolicyConstants.KMA.forecastPageSize, ttl: PolicyConstants.CacheTTL.weatherForecast)
        async let daily = kma(APIConstants.KMA.villageForecastPath, base: .dailyExtremesForecast(at: now, calendar: calendar), grid: grid, pageSize: PolicyConstants.KMA.forecastPageSize, ttl: PolicyConstants.CacheTTL.weatherForecast)
        async let air = airMeasurement(stationName: stationName)

        let nowcastResult = try await nowcast
        let forecastResult = try await forecast
        let dailyItems = (try? await daily)?.value ?? []
        let airLevels = AirQualityMapper.levels((try? await air)?.value ?? nil)

        let weather = try KMAWeatherMapper.map(nowcast: nowcastResult.value, forecast: forecastResult.value, dailyForecast: dailyItems, now: now, calendar: calendar)
        let summary = WeatherSummary(
            temperatureCelsius: weather.temperatureCelsius,
            condition: weather.condition,
            highCelsius: weather.highCelsius,
            lowCelsius: weather.lowCelsius,
            pm10: airLevels.pm10,
            pm25: airLevels.pm25,
            rainStartHour: weather.rainStartHour
        )
        let parts = [nowcastResult.freshness, forecastResult.freshness]
        let freshness = parts.first { $0 != .live } ?? .live
        return Timestamped(value: summary, fetchedAt: min(nowcastResult.fetchedAt, forecastResult.fetchedAt), freshness: freshness)
    }

    private func kma(_ path: String, base: KMABaseTime, grid: GridPoint, pageSize: Int, ttl: Duration) async throws -> Timestamped<[KMAItemDTO]> {
        let key = "kma.\(path).\(base.date)\(base.time).\(grid.nx).\(grid.ny)"
        let requester = requester
        return try await fetcher.fetch(key: key, api: .kma, ttl: ttl) {
            try await requester.kmaItems(path: path, base: base, grid: grid, pageSize: pageSize)
        }
    }

    private func airMeasurement(stationName: String) async throws -> Timestamped<AirKoreaMeasurementDTO?> {
        typealias Keys = APIConstants.AirKorea
        let requester = requester
        return try await fetcher.fetch(key: "air.\(stationName)", api: .airKorea, ttl: PolicyConstants.CacheTTL.airQuality) {
            try await requester.airMeasurements(
                path: Keys.stationMeasurementPath,
                query: [Keys.stationName: stationName, Keys.numOfRows: "1", Keys.dataTerm: Keys.dataTermDaily]
            ).first
        }
    }
}
