import Foundation

/// 앱과 위젯 익스텐션이 같이 쓰는 식별자. (SharedAppGroup: 두 타깃 멤버십)
nonisolated enum SharedConstants {
    /// 두 타깃의 entitlements에 같은 값이 있어야 한다
    static let appGroupID = "group.com.jiyong.Moningseutendeu"
    static let dashboardSnapshotKey = "shared.dashboardSnapshot"
    static let departureWidgetKind = "DepartureWidget"
    /// 스냅샷이 이보다 오래되면 위젯에 "N분 전 정보"를 흐리게 보여준다
    static let staleSnapshotSeconds: TimeInterval = 30 * 60
}
