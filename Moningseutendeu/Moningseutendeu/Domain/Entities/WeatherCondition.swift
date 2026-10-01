import Foundation

/// 기상청 하늘상태(SKY)·강수형태(PTY)를 합친 현재 날씨.
nonisolated enum WeatherCondition: Sendable, Equatable, CaseIterable {
    case clear
    case partlyCloudy
    case cloudy
    case rain
    case snow
}
