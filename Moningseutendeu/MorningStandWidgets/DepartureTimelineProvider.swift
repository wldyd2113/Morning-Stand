import Foundation
import WidgetKit

/// 앱이 써 둔 스냅샷으로 타임라인을 만든다. 네트워크는 쓰지 않는다.
/// 앱이 1분 간격 출발 단계(`moments`)를 미리 계산해 두므로, 그 시각마다 entry를 하나씩 만든다.
nonisolated struct DepartureTimelineProvider: TimelineProvider {
    private let store = DashboardSnapshotStore()

    func placeholder(in context: Context) -> DepartureWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (DepartureWidgetEntry) -> Void) {
        guard !context.isPreview, let snapshot = store.load() else {
            completion(.placeholder)
            return
        }
        completion(Self.entries(for: snapshot, now: .now).first ?? .placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<DepartureWidgetEntry>) -> Void) {
        // 위젯 프로세스에는 DateProvider 주입이 없어 시스템 시각을 쓴다
        let now = Date.now
        guard let snapshot = store.load() else {
            completion(Timeline(entries: [DepartureWidgetEntry(date: now, snapshot: nil, moment: nil)], policy: .never))
            return
        }
        // 마지막 단계 이후는 앱이 새 스냅샷을 쓰고 다시 불러올 때까지 그대로 둔다
        completion(Timeline(entries: Self.entries(for: snapshot, now: now), policy: .never))
    }

    static func entries(for snapshot: DashboardSnapshot, now: Date) -> [DepartureWidgetEntry] {
        let moments = snapshot.departure?.moments ?? []
        let current = DepartureWidgetEntry(date: now, snapshot: snapshot, moment: snapshot.departure?.moment(at: now))
        let upcoming = moments
            .filter { $0.date > now }
            .map { DepartureWidgetEntry(date: $0.date, snapshot: snapshot, moment: $0) }
        return [current] + upcoming
    }
}
