import Foundation

/// 스탠드 화면 위 패널에 쓰는 현재 날씨와 대기질 요약.
nonisolated struct WeatherSummary: Sendable, Equatable {
    var temperatureCelsius: Int
    var condition: WeatherCondition
    var highCelsius: Int
    var lowCelsius: Int
    var pm10: AirQualityLevel
    var pm25: AirQualityLevel
    /// 오늘 비가 시작되는 시각(0~23시). 비 예보가 없으면 `nil`.
    var rainStartHour: Int?
}
