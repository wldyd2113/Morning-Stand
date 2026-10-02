import Foundation
import Synchronization

/// Preview·UI 테스트용 출근 기록. 앱을 끄면 사라진다.
nonisolated final class InMemoryCommuteHistoryRepository: CommuteHistoryRepository {
    // Mutex로 보호하므로 여러 Task에서 안전하게 읽고 쓴다
    private let storage: Mutex<[CommuteRecord]>

    init(records: [CommuteRecord] = []) {
        storage = Mutex(records)
    }

    func records(since start: Date) async throws -> [CommuteRecord] {
        storage.withLock { records in records.filter { $0.leftHomeAt >= start }.sorted { $0.leftHomeAt < $1.leftHomeAt } }
    }

    func save(_ record: CommuteRecord) async throws {
        storage.withLock { records in
            records.removeAll { $0.id == record.id }
            records.append(record)
        }
    }

    func delete(id: UUID) async throws {
        storage.withLock { records in records.removeAll { $0.id == id } }
    }

    /// 지난 3주 평일 출근 기록. 요일·노선별로 소요 시간이 조금씩 다르게 만든다 (값은 고정이라 스냅샷이 흔들리지 않는다).
    static func sampleRecords(endingAt now: Date, calendar: Calendar) -> [CommuteRecord] {
        let routes = ["1711", "7212", "1711", "720", "1711"]
        let leaveOffsets = [38, 41, 36, 44, 40, 39, 47, 37, 42, 35, 40, 43, 38, 46, 41]
        let boardMinutes = [12, 15, 11, 18, 13, 12, 19, 11, 16, 10, 13, 17, 12, 20, 14]
        let today = calendar.startOfDay(for: now)
        let days = (1...21).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
            .filter { !(Weekday(rawValue: calendar.component(.weekday, from: $0))?.isWeekend ?? true) }
            .reversed()
        return days.enumerated().compactMap { index, day in
            let slot = index % leaveOffsets.count
            guard let leftAt = calendar.date(bySettingHour: 7, minute: leaveOffsets[slot], second: 0, of: day) else { return nil }
            let missed = boardMinutes[slot] >= 17
            return CommuteRecord(
                id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index)) ?? UUID(),
                leftHomeAt: leftAt,
                reachedStopAt: leftAt.addingTimeInterval(.minutes(6)),
                stopName: "연신내역",
                kind: .bus,
                routeName: routes[index % routes.count],
                boardedAt: leftAt.addingTimeInterval(.minutes(boardMinutes[slot])),
                missedPlannedVehicle: missed
            )
        }
    }
}
