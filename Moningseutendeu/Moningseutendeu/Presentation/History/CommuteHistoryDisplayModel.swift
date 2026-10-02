import Foundation

/// 출근 기록·통계 탭이 그리는 값.
nonisolated struct CommuteHistoryDisplayModel: Sendable, Equatable {
    var periodText: String
    var tiles: [Tile]
    var weekdayBars: [WeekdayBar]
    var departurePoints: [DeparturePoint]
    /// 출발 시각 차트의 y축 범위 (자정 기준 분)
    var departureAxisMinutes: ClosedRange<Int>
    var rows: [Row]
    var isLoading: Bool
    /// 기록이 없거나 불러오지 못했을 때
    var message: String?
    var actionError: String?

    nonisolated struct Tile: Sendable, Equatable, Identifiable {
        var id: String
        var label: String
        var value: String
        var detail: String?
    }

    nonisolated struct WeekdayBar: Sendable, Equatable, Identifiable {
        /// "월"
        var label: String
        var averageMinutes: Double
        /// "평균 14분 · 5회"
        var valueText: String
        var id: String { label }
    }

    nonisolated struct DeparturePoint: Sendable, Equatable, Identifiable {
        var day: Date
        var minuteOfDay: Int
        var missed: Bool
        /// "9월 30일 (수) 오전 7:42 출발 · 놓침"
        var accessibilityText: String
        var id: Date { day }
    }

    nonisolated struct Row: Sendable, Equatable, Identifiable {
        var id: UUID
        /// "9월 30일 (수)"
        var dateText: String
        /// "오전 7:42 출발 · 1711번"
        var detail: String
        /// "14분" (모르면 "—")
        var minutesText: String
        var missed: Bool
    }
}
