import Foundation
import WidgetKit

/// App Group에 스냅샷을 쓰고, 값이 의미 있게 바뀌었을 때만 위젯 타임라인을 다시 불러온다 (갱신 예산 절약).
final class WidgetCenterSnapshotPublisher: WidgetSnapshotPublishing {
    private let store = DashboardSnapshotStore()
    private var lastReloaded: DashboardSnapshot?

    func publish(_ snapshot: DashboardSnapshot) {
        store.save(snapshot)
        guard Self.needsReload(previous: lastReloaded, next: snapshot) else { return }
        lastReloaded = snapshot
        WidgetCenter.shared.reloadTimelines(ofKind: SharedConstants.departureWidgetKind)
    }

    /// 노선·상태·날씨가 바뀌었거나 도착 시각이 1분 이상 달라졌을 때만 다시 그린다
    nonisolated static func needsReload(previous: DashboardSnapshot?, next: DashboardSnapshot) -> Bool {
        guard let previous else { return true }
        if previous.weather != next.weather { return true }
        let old = previous.departure
        let new = next.departure
        if old?.routeTitle != new?.routeTitle || old?.statusText != new?.statusText { return true }
        switch (old?.arrivalAt, new?.arrivalAt) {
        case (nil, nil): return false
        case let (oldDate?, newDate?): return abs(oldDate.timeIntervalSince(newDate)) >= PolicyConstants.Widget.reloadThresholdSeconds
        default: return true
        }
    }
}
