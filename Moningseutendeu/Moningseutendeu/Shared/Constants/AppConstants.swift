import Foundation

/// 앱 전역 식별자와 키.
nonisolated enum AppConstants {
    enum Region {
        static let localeIdentifier = "ko_KR"
        static let timeZoneIdentifier = "Asia/Seoul"
    }

    /// Info.plist 키 (값은 Config/Secrets.xcconfig에서 빌드 때 채워진다)
    enum InfoPlistKey {
        static let dataGoKrServiceKey = "DATA_GO_KR_SERVICE_KEY"
        static let seoulSubwayKey = "SEOUL_OPEN_DATA_SUBWAY_KEY"
        static let kmaBaseURL = "KMA_BASE_URL"
        static let airKoreaBaseURL = "AIRKOREA_BASE_URL"
        static let seoulBusBaseURL = "SEOUL_BUS_BASE_URL"
        static let seoulSubwayBaseURL = "SEOUL_SUBWAY_BASE_URL"
    }

    enum UserDefaultsKey {
        static let favoriteStops = "settings.favoriteStops"
        static let airQualityStation = "settings.airQualityStation"
        static let commuteRoutes = "settings.commuteRoutes"
        static let routines = "settings.routines"
        /// 일일 호출 수. 뒤에 API 이름과 날짜를 붙인다
        static let rateLimitPrefix = "rateLimit."
    }

    enum Logging {
        static let subsystem = "com.jiyong.Moningseutendeu"
        static let networkCategory = "network"
        static let configurationCategory = "configuration"
    }

    enum LaunchArgument {
        /// `-posture halfOpened|flat|closed`: 자세 판정을 고정한다
        static let posture = "-posture"
        /// `-standScenario soon|relaxed|now|missed|loading|weatherStale|offline|ended`
        static let standScenario = "-standScenario"
        /// `-theme day|night`: 스탠드 화면 테마를 시각과 상관없이 고정한다
        static let theme = "-theme"
        /// 실제 API 대신 샘플 데이터를 쓴다 (UI 테스트·데모)
        static let useSampleData = "-useSampleData"
    }

    enum AccessibilityID {
        static let standRoot = "stand.root"
        static let standClock = "stand.clock"
        static let standHero = "stand.hero"
        static let standOtherRoutes = "stand.otherRoutes"
        static let planningRoot = "planning.root"
        static let modeToggle = "root.modeToggle"
        static let settingsButton = "planning.settings"
        static let addRouteButton = "planning.addRoute"
        static let editRouteButton = "planning.editRoute"
        static let stopSearchField = "settings.stopSearch.field"
        static let addFavoriteButton = "settings.stopSearch.addFavorite"
    }
}
