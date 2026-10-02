import Foundation

/// 출근 한 번의 기록. 집을 나선 시각, 정류장 도착 시각, 탄 차량을 남긴다.
nonisolated struct CommuteRecord: Sendable, Equatable, Identifiable {
    var id: UUID
    /// 집을 나선 시각
    var leftHomeAt: Date
    /// 정류장 근처에 도착한 시각. 아직 도착 전이면 `nil`
    var reachedStopAt: Date?
    var stopName: String
    var kind: TransportKind
    /// 탄(탈 예정인) 노선 이름. 도착 정보가 없었으면 `nil`
    var routeName: String?
    /// 탄 차량이 정류장에 도착하는 (예상) 시각
    var boardedAt: Date?
    /// 집을 나설 때 이미 앱이 안내한 차량을 놓친 상태였는지
    var missedPlannedVehicle: Bool

    /// 집 → 탑승까지 걸린 시간(분). 탑승 시각을 모르면 `nil`
    var doorToBoardMinutes: Int? {
        guard let boardedAt, boardedAt >= leftHomeAt else { return nil }
        return Int((boardedAt.timeIntervalSince(leftHomeAt) / 60).rounded())
    }
}
