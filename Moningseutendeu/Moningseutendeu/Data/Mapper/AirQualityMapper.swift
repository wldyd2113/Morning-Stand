import Foundation

/// 에어코리아 측정값 → 등급. 등급 필드가 비면 수치로 계산하고, 둘 다 없으면 `.unavailable`.
nonisolated enum AirQualityMapper {
    static func levels(_ dto: AirKoreaMeasurementDTO?) -> (pm10: AirQualityLevel, pm25: AirQualityLevel) {
        guard let dto else { return (.unavailable, .unavailable) }
        return (
            level(grade: dto.pm10Grade ?? dto.pm10Grade1h, value: dto.pm10Value, thresholds: PolicyConstants.AirQuality.pm10Thresholds),
            level(grade: dto.pm25Grade ?? dto.pm25Grade1h, value: dto.pm25Value, thresholds: PolicyConstants.AirQuality.pm25Thresholds)
        )
    }

    /// 등급 1 좋음, 2 보통, 3 나쁨, 4 매우나쁨
    static func level(grade: String?, value: String?, thresholds: [Int]) -> AirQualityLevel {
        switch grade {
        case "1": return .good
        case "2": return .moderate
        case "3": return .bad
        case "4": return .veryBad
        default: break
        }
        guard let value, value != APIConstants.AirKorea.missingValue, let number = Int(value) else { return .unavailable }
        let levels: [AirQualityLevel] = [.good, .moderate, .bad]
        for (threshold, level) in zip(thresholds, levels) where number <= threshold {
            return level
        }
        return .veryBad
    }
}
