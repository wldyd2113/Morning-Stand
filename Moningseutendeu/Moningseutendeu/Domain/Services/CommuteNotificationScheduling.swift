import Foundation

/// 출근 관련 로컬 알림. 구현(UserNotifications)은 Platform에 있다.
nonisolated protocol CommuteNotificationScheduling: Sendable {
    /// 알림 권한을 요청한다. 허용됐는지 돌려준다
    func requestAuthorization() async -> Bool
    /// 정류장 근처에 왔을 때 바로 보여줄 알림. 같은 알림이 있으면 바꾼다
    func notifyNearStop(title: String, body: String) async
}
