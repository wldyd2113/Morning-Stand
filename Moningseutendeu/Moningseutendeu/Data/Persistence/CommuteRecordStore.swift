import Foundation
import SwiftData

/// 출근 기록 SwiftData 작업. `@Model`은 이 actor 밖으로 나가지 않고, 도메인 struct로 바꿔서 돌려준다.
@ModelActor
actor CommuteRecordStore {
    func records(since start: Date) throws -> [CommuteRecord] {
        let descriptor = FetchDescriptor<CommuteRecordModel>(
            predicate: #Predicate { $0.leftHomeAt >= start },
            sortBy: [SortDescriptor(\.leftHomeAt)]
        )
        return try modelContext.fetch(descriptor).map(Self.record(from:))
    }

    func upsert(_ record: CommuteRecord) throws {
        if let existing = try model(id: record.id) {
            existing.leftHomeAt = record.leftHomeAt
            existing.reachedStopAt = record.reachedStopAt
            existing.stopName = record.stopName
            existing.kindRawValue = record.kind.rawValue
            existing.routeName = record.routeName
            existing.boardedAt = record.boardedAt
            existing.missedPlannedVehicle = record.missedPlannedVehicle
        } else {
            modelContext.insert(CommuteRecordModel(
                id: record.id,
                leftHomeAt: record.leftHomeAt,
                reachedStopAt: record.reachedStopAt,
                stopName: record.stopName,
                kindRawValue: record.kind.rawValue,
                routeName: record.routeName,
                boardedAt: record.boardedAt,
                missedPlannedVehicle: record.missedPlannedVehicle
            ))
        }
        try modelContext.save()
    }

    func delete(id: UUID) throws {
        guard let existing = try model(id: id) else { return }
        modelContext.delete(existing)
        try modelContext.save()
    }

    private func model(id: UUID) throws -> CommuteRecordModel? {
        var descriptor = FetchDescriptor<CommuteRecordModel>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private static func record(from model: CommuteRecordModel) -> CommuteRecord {
        CommuteRecord(
            id: model.id,
            leftHomeAt: model.leftHomeAt,
            reachedStopAt: model.reachedStopAt,
            stopName: model.stopName,
            kind: TransportKind(rawValue: model.kindRawValue) ?? .bus,
            routeName: model.routeName,
            boardedAt: model.boardedAt,
            missedPlannedVehicle: model.missedPlannedVehicle
        )
    }
}
