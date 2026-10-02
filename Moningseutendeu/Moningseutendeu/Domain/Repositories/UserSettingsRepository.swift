import Foundation

/// 사용자 설정 저장소 (즐겨찾기 정류장, 미세먼지 측정소, 집 위치, 출근 자동 처리).
nonisolated protocol UserSettingsRepository: Sendable {
    func favoriteStops() -> [FavoriteStop]
    func saveFavoriteStop(_ stop: FavoriteStop)
    func removeFavoriteStop(id: String)
    /// 즐겨찾기 순서를 통째로 바꾼다 (첫 번째가 스탠드 화면에 나온다)
    func setFavoriteStops(_ stops: [FavoriteStop])
    func airQualityStationName() -> String
    func setAirQualityStationName(_ name: String)
    /// 날씨 격자와 "집을 나섬" 감시에 쓰는 집 좌표. 설정 전이면 `nil`
    func homeLocation() -> Coordinate?
    func setHomeLocation(_ coordinate: Coordinate?)
    /// 집을 나서면 Live Activity 종료·정류장 근처 알림·출근 기록을 자동으로 할지
    func isCommuteAutomationEnabled() -> Bool
    func setCommuteAutomationEnabled(_ isEnabled: Bool)
    /// 지역 감시의 마지막 안/밖 상태. 앱이 다시 실행돼도 "나감"을 판단하려고 저장한다
    func lastRegionPresence(_ region: CommuteRegion) -> RegionPresence?
    func setLastRegionPresence(_ presence: RegionPresence?, for region: CommuteRegion)
}
