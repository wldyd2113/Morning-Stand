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
        static let homeLocation = "settings.homeLocation"
        static let commuteAutomationEnabled = "settings.commuteAutomationEnabled"
        /// 지역 감시 마지막 상태. 뒤에 지역 이름을 붙인다
        static let regionPresencePrefix = "regionMonitor.presence."
        /// 일일 호출 수. 뒤에 API 이름과 날짜를 붙인다
        static let rateLimitPrefix = "rateLimit."
    }

    enum Logging {
        static let subsystem = "com.jiyong.Moningseutendeu"
        static let networkCategory = "network"
        static let configurationCategory = "configuration"
        static let liveActivityCategory = "liveActivity"
        static let locationCategory = "location"
        static let historyCategory = "history"
    }

    enum RegionMonitor {
        /// CLMonitor 이름. 같은 이름으로 다시 열면 앱을 다시 켜도 감시 조건이 이어진다
        static let monitorName = "MorningStandCommute"
    }

    enum SystemURL {
        /// 이 앱의 설정 화면 (`UIApplication.openSettingsURLString`과 같은 값)
        static let appSettings = "app-settings:"
    }

    enum NotificationID {
        static let nearStop = "commute.nearStop"
    }

    enum Persistence {
        /// SwiftData 저장 파일 이름
        static let historyStoreName = "CommuteHistory"
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
        /// 출근 시간대가 아니어도 Live Activity를 띄운다 (확인·시연용)
        static let liveActivityAnyTime = "-liveActivityAnyTime"
        /// `-planningTab routes|nearby|history`: 펼침 화면에서 처음 보여줄 탭
        static let planningTab = "-planningTab"
        /// `-motion resting|handheld`: 움직임 상태를 고정한다 (센서가 없는 시뮬레이터 확인용)
        static let motion = "-motion"
    }

    enum AccessibilityID {
        static let standRoot = "stand.root"
        static let glanceRoot = "glance.root"
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
        static let planningTabs = "planning.tabs"
        static let nearbyRoot = "nearby.root"
        static let nearbyFindButton = "nearby.find"
        static let nearbyMap = "nearby.map"
        static let nearbyArrivals = "nearby.arrivals"
        static let nearbySetHomeButton = "nearby.setHome"
        static let nearbyAutomationToggle = "nearby.automation"
        static let historyRoot = "history.root"
        static let historyLeaveNowButton = "history.leaveNow"
    }
}
