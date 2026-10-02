import Foundation

/// 집·정류장 지역 감시. 구현(CLMonitor)은 Platform에 있다.
nonisolated protocol CommuteRegionMonitoring: Sendable {
    /// 지역 안/밖 상태 변화. 앱이 실행되는 동안 한 곳에서만 구독한다
    func presenceChanges() async -> AsyncStream<RegionPresenceChange>
    /// 감시할 지역을 바꾼다. `nil`이면 그 지역은 감시를 끈다
    func monitor(home: Coordinate?, stop: Coordinate?) async
    /// 집을 벗어난 것을 앱이 꺼져 있어도 알려면 "항상" 권한이 필요하다. 허용됐는지 돌려준다
    func requestAlwaysAuthorization() async -> Bool
}
