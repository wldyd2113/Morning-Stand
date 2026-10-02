import Foundation

/// App Group UserDefaults에 스냅샷을 JSON으로 읽고 쓴다. 디코딩에 실패하면(스키마 변경 등) nil을 돌려준다.
nonisolated struct DashboardSnapshotStore: Sendable {
    private var defaults: UserDefaults? { UserDefaults(suiteName: SharedConstants.appGroupID) }

    func load() -> DashboardSnapshot? {
        guard let data = defaults?.data(forKey: SharedConstants.dashboardSnapshotKey),
              let snapshot = try? JSONDecoder().decode(DashboardSnapshot.self, from: data),
              snapshot.schemaVersion == DashboardSnapshot.currentSchemaVersion else { return nil }
        return snapshot
    }

    func save(_ snapshot: DashboardSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: SharedConstants.dashboardSnapshotKey)
    }
}
