import Foundation

/// 펼침 플래닝 화면이 그리는 값.
nonisolated struct PlanningDisplayModel: Sendable, Equatable {
    var content: Content
    var routes: [RouteRow]
    var detail: Detail?
    var legend: [LegendItem]
    var weekdays: [DayChip]
    var routineSummary: String
    var routine: Routine?

    nonisolated enum Content: Sendable, Equatable {
        case loading
        /// 저장된 경로가 없음
        case empty
        case loaded
        case failed(message: String)
    }

    nonisolated struct RouteRow: Sendable, Equatable, Identifiable {
        var id: String
        var name: String
        var schedule: String
        var bestText: String
        var isSelected: Bool
    }

    nonisolated struct Detail: Sendable, Equatable {
        var title: String
        var subtitle: String
        var options: [Option]
    }

    nonisolated struct Option: Sendable, Equatable, Identifiable {
        var id: String
        var totalText: String
        var isFastest: Bool
        var title: String
        var tag: String
        var arrivalText: String
        var segments: [Segment]
        var accessibilityLabel: String
    }

    nonisolated struct Segment: Sendable, Equatable, Identifiable {
        var id: Int
        var kind: RouteSegment.Kind
        var minutes: Int
        var caption: String
        /// 자리가 모자랄 때 쓰는 짧은 캡션 (분만)
        var compactCaption: String
    }

    nonisolated struct LegendItem: Sendable, Equatable, Identifiable {
        var kind: RouteSegment.Kind
        var name: String
        var id: RouteSegment.Kind { kind }
    }

    nonisolated struct DayChip: Sendable, Equatable, Identifiable {
        var weekday: Weekday
        var label: String
        var isSelected: Bool
        var isEnabled: Bool
        var id: Weekday { weekday }
    }

    nonisolated struct Routine: Sendable, Equatable {
        var toggleTitle: String
        var isEnabled: Bool
        var timeText: String
        var routeText: String
        var alertText: String
    }
}
