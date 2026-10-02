import Foundation

/// 출근 자동 처리 (집을 나섬·정류장 근처). ViewModel은 이 프로토콜만 안다.
@MainActor
protocol CommuteAutomationControlling: AnyObject {
    var isEnabled: Bool { get }
    /// 켤 때 "항상" 위치 권한과 알림 권한을 요청한다. 켜지 못하면 이유를 던진다
    func setEnabled(_ isEnabled: Bool) async throws(CommuteAutomationError)
    /// 집·즐겨찾기 정류장이 바뀌었을 때 감시 지역을 다시 맞춘다
    func syncRegions() async
    /// 직접 "지금 출발"을 기록한다 (지역 감시를 쓰지 않거나 시뮬레이터일 때)
    func recordLeavingNow() async throws
}
