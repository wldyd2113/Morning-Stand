import Foundation
import SwiftData

/// 출근 기록 스키마 이력. 아직 1판뿐이라 단계가 없다.
nonisolated enum CommuteHistoryMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [CommuteHistorySchemaV1.self] }
    static var stages: [MigrationStage] { [] }

    /// 앱 전체에서 하나만 만든다. `inMemory`는 Preview·UI 테스트용.
    static func makeContainer(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema(versionedSchema: CommuteHistorySchemaV1.self)
        let configuration = ModelConfiguration(AppConstants.Persistence.historyStoreName, schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, migrationPlan: Self.self, configurations: configuration)
    }
}
