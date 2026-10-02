import Foundation
import Observation

/// 출근 기록·통계 탭 상태.
@MainActor @Observable
final class CommuteHistoryViewModel {
    private(set) var records: SectionState<[CommuteRecord]> = .idle
    private(set) var isRecording = false
    private(set) var actionError: String?

    @ObservationIgnored private let repository: any CommuteHistoryRepository
    @ObservationIgnored private let automation: any CommuteAutomationControlling
    @ObservationIgnored private let dateProvider: any DateProvider
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private let statistics: CommuteStatisticsUseCase

    init(
        repository: any CommuteHistoryRepository,
        automation: any CommuteAutomationControlling,
        dateProvider: any DateProvider,
        calendar: Calendar = .seoul,
        statistics: CommuteStatisticsUseCase = CommuteStatisticsUseCase()
    ) {
        self.repository = repository
        self.automation = automation
        self.dateProvider = dateProvider
        self.calendar = calendar
        self.statistics = statistics
    }

    var display: CommuteHistoryDisplayModel {
        CommuteHistoryDisplayMapper.make(
            records: records,
            statistics: statistics(records.value ?? [], calendar: calendar),
            actionError: actionError,
            calendar: calendar
        )
    }

    func axisTimeText(minuteOfDay: Int) -> String {
        CommuteHistoryDisplayMapper.axisTimeText(minuteOfDay: minuteOfDay)
    }

    /// 탭이 보일 때마다 부른다 (자동 처리가 백그라운드에서 기록을 추가했을 수 있다).
    func load() async {
        records = records.beginningLoad()
        let now = dateProvider.now
        let start = calendar.date(byAdding: .day, value: -PolicyConstants.History.lookbackDays, to: calendar.startOfDay(for: now)) ?? now
        do {
            let fetched = try await repository.records(since: start)
            guard !Task.isCancelled else { return }
            records = .loaded(fetched, fetchedAt: now)
        } catch {
            guard !Task.isCancelled else { return }
            records = records.resolved(with: .failure(AppError(error)))
        }
    }

    func recordLeavingNow() async {
        guard !isRecording else { return }
        isRecording = true
        actionError = nil
        defer { isRecording = false }
        do {
            try await automation.recordLeavingNow()
            await load()
        } catch {
            actionError = AppError(error).userMessage
        }
    }

    func delete(id: UUID) async {
        do {
            try await repository.delete(id: id)
            await load()
        } catch {
            actionError = AppError(error).userMessage
        }
    }
}
