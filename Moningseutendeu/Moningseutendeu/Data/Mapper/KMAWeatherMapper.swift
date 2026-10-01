import Foundation

/// 기상청 실황·예보 항목 → 현재 날씨 요약 (미세먼지 제외).
nonisolated enum KMAWeatherMapper {
    typealias Category = APIConstants.KMA.Category

    struct Result: Sendable, Equatable {
        var temperatureCelsius: Int
        var condition: WeatherCondition
        var highCelsius: Int
        var lowCelsius: Int
        var rainStartHour: Int?
    }

    /// - Parameters:
    ///   - nowcast: 초단기실황 (현재 기온 T1H, 강수형태 PTY)
    ///   - forecast: 최근 단기예보 (하늘상태 SKY, 시간별 기온·강수)
    ///   - dailyForecast: 오늘 02시 단기예보 (오늘 최고·최저 TMX·TMN)
    static func map(nowcast: [KMAItemDTO], forecast: [KMAItemDTO], dailyForecast: [KMAItemDTO], now: Date, calendar: Calendar) throws -> Result {
        let today = KSTDateParser.compactDate(now, calendar: calendar)
        let currentSlot = today + String(format: "%02d00", calendar.component(.hour, from: now))
        let upcoming = forecast
            .filter { slot($0) >= currentSlot }
            .sorted { slot($0) < slot($1) }

        let nowTemperature = value(nowcast.first { $0.category == Category.temperatureNow }?.obsrValue)
            ?? value(upcoming.first { $0.category == Category.temperatureHourly }?.fcstValue)
        guard let temperature = nowTemperature else { throw AppError.decoding }

        let precipitation = value(nowcast.first { $0.category == Category.precipitationType }?.obsrValue).map { Int($0) }
        let sky = value(upcoming.first { $0.category == Category.sky }?.fcstValue).map { Int($0) }

        let todayItems = (dailyForecast + forecast).filter { $0.fcstDate == today }
        let hourlyTemperatures = todayItems.filter { $0.category == Category.temperatureHourly }.compactMap { value($0.fcstValue) } + [temperature]
        let high = value(todayItems.first { $0.category == Category.dailyMax }?.fcstValue) ?? hourlyTemperatures.max() ?? temperature
        let low = value(todayItems.first { $0.category == Category.dailyMin }?.fcstValue) ?? hourlyTemperatures.min() ?? temperature

        return Result(
            temperatureCelsius: Int(temperature.rounded()),
            condition: condition(precipitationType: precipitation, sky: sky),
            highCelsius: Int(high.rounded()),
            lowCelsius: Int(low.rounded()),
            rainStartHour: rainStartHour(upcoming.filter { $0.fcstDate == today })
        )
    }

    /// PTY(0 없음, 1 비, 2 비/눈, 3 눈, 4 소나기, 5 빗방울, 6 빗방울눈날림, 7 눈날림)가 우선, 없으면 SKY(1 맑음, 3 구름많음, 4 흐림)
    static func condition(precipitationType: Int?, sky: Int?) -> WeatherCondition {
        switch precipitationType {
        case 1, 2, 4, 5, 6: return .rain
        case 3, 7: return .snow
        default: break
        }
        switch sky {
        case 3: return .partlyCloudy
        case 4: return .cloudy
        default: return .clear
        }
    }

    /// 오늘 남은 시간 중 처음으로 비(PTY ≠ 0) 또는 강수확률이 기준 이상인 시각
    static func rainStartHour(_ items: [KMAItemDTO]) -> Int? {
        let rainy = items.filter { item in
            switch item.category {
            case Category.precipitationType:
                return (value(item.fcstValue) ?? 0) != 0
            case Category.precipitationProbability:
                return (value(item.fcstValue) ?? 0) >= Double(PolicyConstants.KMA.rainProbabilityThresholdPercent)
            default:
                return false
            }
        }
        guard let first = rainy.min(by: { slot($0) < slot($1) }), let time = first.fcstTime, time.count >= 2 else { return nil }
        return Int(time.prefix(2))
    }

    /// 숫자로 바꾸고 결측(±900 이상)은 nil
    static func value(_ text: String?) -> Double? {
        guard let text, let number = Double(text) else { return nil }
        return abs(number) >= PolicyConstants.KMA.missingValueThreshold ? nil : number
    }

    private static func slot(_ item: KMAItemDTO) -> String {
        (item.fcstDate ?? "") + (item.fcstTime ?? "")
    }
}
