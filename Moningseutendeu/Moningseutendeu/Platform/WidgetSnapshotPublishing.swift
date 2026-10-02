import Foundation

/// 위젯이 읽을 스냅샷을 내보낸다. ViewModel은 WidgetKit을 모르고 이 프로토콜만 안다.
protocol WidgetSnapshotPublishing {
    func publish(_ snapshot: DashboardSnapshot)
}

/// Preview·테스트용. 아무것도 하지 않는다.
struct NoopWidgetSnapshotPublisher: WidgetSnapshotPublishing {
    func publish(_ snapshot: DashboardSnapshot) {}
}
