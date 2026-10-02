import Foundation
import SwiftData

/// 출근 기록 스키마 1판. 모델이 바뀌면 `SchemaV2`를 만들고 `CommuteHistoryMigrationPlan`에 단계를 추가한다.
nonisolated enum CommuteHistorySchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [CommuteRecordModel.self] }

    /// 출근 한 번. 도메인 `CommuteRecord`와 따로 두고 `CommuteRecordStore`에서 바꾼다.
    @Model
    nonisolated final class CommuteRecordModel {
        @Attribute(.unique) var id: UUID
        var leftHomeAt: Date
        var reachedStopAt: Date?
        var stopName: String
        /// `TransportKind.rawValue`
        var kindRawValue: String
        var routeName: String?
        var boardedAt: Date?
        var missedPlannedVehicle: Bool

        init(id: UUID, leftHomeAt: Date, reachedStopAt: Date?, stopName: String, kindRawValue: String, routeName: String?, boardedAt: Date?, missedPlannedVehicle: Bool) {
            self.id = id
            self.leftHomeAt = leftHomeAt
            self.reachedStopAt = reachedStopAt
            self.stopName = stopName
            self.kindRawValue = kindRawValue
            self.routeName = routeName
            self.boardedAt = boardedAt
            self.missedPlannedVehicle = missedPlannedVehicle
        }
    }
}

typealias CommuteRecordModel = CommuteHistorySchemaV1.CommuteRecordModel
