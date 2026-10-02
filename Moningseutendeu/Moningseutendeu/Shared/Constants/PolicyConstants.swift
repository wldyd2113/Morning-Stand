import Foundation

/// 동작 정책 값 (임계값, 주기, 범위). 단위를 이름에 드러낸다.
nonisolated enum PolicyConstants {
    enum Widget {
        /// 위젯 타임라인을 미리 계산하는 길이(분). 스냅샷 크기를 작게 유지한다
        static let timelineMinutes = 60
        /// 도착 시각이 이만큼 이상 바뀌어야 위젯을 다시 그린다 (갱신 예산 절약)
        static let reloadThresholdSeconds: TimeInterval = 60
    }

    enum LiveActivity {
        /// 차량 도착 후 이 시간이 지나도록 갱신이 없으면 오래된 정보로 표시된다
        static let staleAfterArrivalSeconds: TimeInterval = 60
    }

    enum NightTheme {
        /// 이 시각(시)부터 야간 테마
        static let startHour = 22
        /// 이 시각(시)부터 주간 테마
        static let endHour = 6
    }

    enum Stand {
        /// 스탠드 화면의 현재 시각(테마·경과 시간) 갱신 주기
        static let minuteTickInterval: Duration = .seconds(60)
        /// 갱신 시각 표시("12초 전")를 다시 그리는 주기
        static let footerRefreshIntervalSeconds: TimeInterval = 1
    }

    enum Posture {
        /// 창 너비가 이 값(pt) 이상이면 안쪽 큰 화면으로 본다 (커버 화면은 이보다 좁다)
        static let innerDisplayMinimumWidth: CGFloat = 600
    }

    enum Walking {
        static let defaultMinutes = 5
        /// 범위는 Domain의 `WalkingPolicy`와 같은 값을 쓴다
        static let minimumMinutes = WalkingPolicy.standard.minimumMinutes
        static let maximumMinutes = WalkingPolicy.standard.maximumMinutes
    }

    enum Notification {
        static let departureLeadOptionsMinutes = [3, 5, 10, 15]
        static let defaultDepartureLeadMinutes = 5
        static let rainProbabilityThresholdPercent = 60
    }

    enum Network {
        /// 요청 하나의 타임아웃 (공공 API가 가끔 응답 없이 멈춰서 짧게 두고 한 번 다시 시도한다)
        static let requestTimeoutSeconds: TimeInterval = 6
        /// 타임아웃·5xx일 때 다시 시도하는 횟수. 재시도도 호출 한도에 포함된다
        static let maxRetryCount = 1
    }

    /// API별 캐시 유효 시간
    enum CacheTTL {
        static let busArrival: Duration = .seconds(30)
        static let subwayArrival: Duration = .seconds(30)
        static let weatherNowcast: Duration = .seconds(10 * 60)
        static let weatherForecast: Duration = .seconds(60 * 60)
        static let airQuality: Duration = .seconds(30 * 60)
        static let stationList: Duration = .seconds(7 * 24 * 60 * 60)
        /// 주변 정류장은 위치가 같으면 잘 바뀌지 않는다
        static let nearbyStops: Duration = .seconds(24 * 60 * 60)
        /// 실패했을 때 이보다 오래된 캐시는 보여주지 않는다
        static let staleLimit: Duration = .seconds(3 * 60 * 60)
    }

    /// 앱이 스스로 지키는 일일 호출 한도 (포털 한도보다 약간 낮게)
    enum DailyLimit {
        static let seoulBus = 950
        static let seoulSubway = 950
        static let kma = 9_500
        static let airKorea = 450
    }

    /// 스탠드 화면 갱신 주기
    enum Polling {
        /// 출근 시간대 (시작 시 이상, 끝 시 미만)
        static let commuteStartHour = CommuteHourPolicy.standard.startHour
        static let commuteEndHour = CommuteHourPolicy.standard.endHour
        /// 출근 시간대 갱신 주기
        static let commuteInterval: Duration = .seconds(60)
        /// 그 외 시간대 갱신 주기 (서울 버스 1,000건/일 한도 보호)
        static let offPeakInterval: Duration = .seconds(5 * 60)
    }

    enum KMA {
        /// 단기예보는 항목이 많아 한 번에 충분히 받아야 오늘 예보가 잘리지 않는다
        static let forecastPageSize = 1_000
        static let nowcastPageSize = 20
        /// 초단기실황은 매시 정각 발표, 이 분(minute) 이후부터 조회 가능
        static let nowcastAvailableMinute = 40
        /// 단기예보 발표 시각 (시)
        static let forecastBaseHours = [2, 5, 8, 11, 14, 17, 20, 23]
        /// 단기예보는 발표 후 이 분(minute) 이후부터 조회 가능
        static let forecastAvailableDelayMinutes = 10
        /// 강수확률이 이 값(%) 이상이면 비 예보로 본다
        static let rainProbabilityThresholdPercent = 60
        /// 이 값 이상·이하는 결측
        static let missingValueThreshold = 900.0
    }

    enum AirQuality {
        /// 미세먼지(PM10) 등급 상한 (좋음, 보통, 나쁨) μg/m³
        static let pm10Thresholds = [30, 80, 150]
        /// 초미세먼지(PM2.5) 등급 상한 (좋음, 보통, 나쁨) μg/m³
        static let pm25Thresholds = [15, 35, 75]
        /// 측정소 목록을 받을 시도
        static let sidoName = "서울"
        /// 설정 전 기본 측정소
        static let defaultStationName = "중구"
    }

    enum Subway {
        /// 남은 시간이 0인 "도착·진입" 기록이 이보다 오래됐으면 이미 떠난 열차로 보고 버린다
        static let staleArrivalRecordSeconds: TimeInterval = 120
        /// 한 번에 받을 도착 정보 수
        static let pageSize = 20
    }

    enum DefaultLocation {
        /// 위치를 모를 때 쓰는 기본 좌표 (서울시청)
        static let coordinate = Coordinate(latitude: 37.5665, longitude: 126.9780)
    }

    enum Location {
        /// 현재 위치를 한 번 받을 때 기다리는 최대 시간
        static let oneShotTimeout: Duration = .seconds(10)
        /// 권한 요청 창이 뜬 경우 기다리는 최대 시간
        static let permissionPromptTimeout: Duration = .seconds(60)
        /// 이 오차(m) 이내의 위치가 오면 바로 쓴다
        static let acceptableAccuracyMeters: Double = 100
        /// 이보다 오차(m)가 크면(대략적 위치) 주변 정류장 찾기에 쓰지 않는다. 날씨에는 쓴다
        static let nearbySearchMaxAccuracyMeters: Double = 500
        /// 주변 정류장 검색 반경(m)
        static let nearbyRadiusMeters = 500
        /// 주변 정류장 캐시 키에 쓰는 좌표 소수 자릿수 (3자리 ≈ 100m)
        static let cacheCoordinateFractionDigits = 3
        /// 주변 정류장 목록에 보여줄 최대 개수
        static let nearbyMaxResults = 15
    }

    /// 지역 감시 (집을 나섬 · 정류장 근처)
    enum RegionMonitor {
        /// 집 범위 반경(m). 너무 작으면 실내 GPS 흔들림에 "나감"이 잘못 잡힌다
        static let homeRadiusMeters: Double = 150
        /// 정류장 근처 반경(m)
        static let stopRadiusMeters: Double = 100
    }

    enum History {
        /// 통계에 쓰는 기간(일)
        static let lookbackDays = 28
        /// 출발 시각 차트 위아래 여유(분)
        static let chartAxisPaddingMinutes = 10
    }

    enum Search {
        /// 검색어 입력이 멈춘 뒤 검색을 시작하기까지 기다리는 시간
        static let debounceInterval: Duration = .milliseconds(300)
    }

    enum RouteEditor {
        /// 새 구간의 기본 탑승 시간(분)
        static let defaultRideMinutes = 15
        /// 첫 정류장 기본 대기 시간(분)
        static let defaultWaitMinutes = 5
        /// 환승 이동 기본 시간(분)
        static let defaultTransferMinutes = 3
        /// 하차 후 기본 도보 시간(분)
        static let defaultFinalWalkMinutes = 5
        static let minimumMinutes = 0
        static let maximumMinutes = 180
        /// 한 이동 방법에 넣을 수 있는 최대 탑승 구간 수 (환승 3회)
        static let maximumLegs = 4
        /// 기본 출발 시각
        static let defaultDepartureHour = 8
    }

    enum Planning {
        /// 구간 길이가 이 시간(분) 이상일 때만 노선 이름까지 표시한다
        static let segmentLabelMinimumMinutes = 6
    }
}
