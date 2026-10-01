import Foundation

/// 스탠드 화면이 그리는 값. 문구·분기는 모두 `StandDisplayMapper`가 만들고, View는 그리기만 한다.
nonisolated struct StandDisplayModel: Sendable, Equatable {
    var theme: DisplayTheme
    var dateText: String
    var weather: WeatherPanel
    var banner: Banner
    var hero: Hero
    var otherRoutes: OtherRoutes
    var footer: Footer

    // MARK: - 시계

    nonisolated struct Clock: Sendable, Equatable {
        var hour: String
        var minute: String
        var accessibilityLabel: String
    }

    // MARK: - 날씨

    nonisolated enum WeatherSymbol: Sendable, Equatable {
        case sun, moon, cloudSun, cloudMoon, cloud, rain, snow
    }

    nonisolated struct AirQualityChip: Sendable, Equatable {
        var label: String
        var level: AirQualityLevel
    }

    nonisolated struct Weather: Sendable, Equatable {
        var symbol: WeatherSymbol
        var temperatureText: String
        var conditionText: String
        var rangeText: String
        var pm10: AirQualityChip
        var pm25: AirQualityChip
        var accessibilityLabel: String
    }

    nonisolated enum WeatherPanel: Sendable, Equatable {
        case placeholder
        case content(Weather, isDimmed: Bool)
        case unavailable(message: String)
    }

    // MARK: - 위 패널 아래줄 배너

    nonisolated enum NoticeStyle: Sendable, Equatable {
        /// 강조색 테두리 배지 (마지막 정보 · N분 전)
        case stale
        /// 회색 배지 (오프라인, 실패)
        case offline
    }

    nonisolated struct Notice: Sendable, Equatable {
        var style: NoticeStyle
        var badge: String
        var message: String
    }

    nonisolated enum Banner: Sendable, Equatable {
        case none
        case placeholder
        case rain(message: String)
        case notice(Notice)
    }

    // MARK: - 히어로 카드

    nonisolated struct DepartureHero: Sendable, Equatable {
        var urgency: DepartureUrgency
        var badge: String
        /// "7", "지금", "놓침"
        var headline: String
        /// 숫자면 더 큰 글자로 그린다
        var isNumericHeadline: Bool
        /// 두 줄 단위 문구 ("분 뒤" / "출발")
        var unitLines: [String]
        var routeTitle: String
        var detail: String
        var accessibilityLabel: String
    }

    nonisolated enum NoticeHeroStyle: Sendable, Equatable {
        case offline
        case ended
        /// 설정 필요, 남은 시간을 모르는 도착 상태 등 안내
        case info
    }

    nonisolated struct NoticeHero: Sendable, Equatable {
        var style: NoticeHeroStyle
        var badge: String
        var headline: String
        var title: String
        var detail: String
    }

    nonisolated enum Hero: Sendable, Equatable {
        case placeholder
        case departure(DepartureHero)
        case notice(NoticeHero)
    }

    // MARK: - 다른 노선

    nonisolated struct RouteRow: Sendable, Equatable, Identifiable {
        var id: String
        var title: String
        var subtitle: String
        var etaText: String
        var nextText: String
    }

    nonisolated enum OtherRoutes: Sendable, Equatable {
        case placeholder
        case rows([RouteRow], isDimmed: Bool)
        case unavailable(message: String)
    }

    // MARK: - 갱신 시각

    nonisolated enum Footer: Sendable, Equatable {
        case loading
        /// 방금 갱신됨. `scope`가 있으면 그 정보만 갱신된 것 ("버스")
        case updated(at: Date, scope: String?)
        /// 갱신이 멈춤 (오프라인 등)
        case lastUpdated(at: Date)
        case unavailable

        var isLive: Bool {
            if case .updated = self { return true }
            return false
        }
    }
}
