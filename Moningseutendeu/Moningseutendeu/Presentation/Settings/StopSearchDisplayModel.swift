import Foundation

/// 정류장 검색·도보 시간 설정 화면이 그리는 값.
nonisolated struct StopSearchDisplayModel: Sendable, Equatable {
    var rows: [Row]
    var isLoading: Bool
    var emptyMessage: String?
    var selection: Selection?

    nonisolated struct Row: Sendable, Equatable, Identifiable {
        var id: String
        var name: String
        var detail: String
        var isSelected: Bool
        var isFavorite: Bool
    }

    nonisolated struct RouteChip: Sendable, Equatable, Identifiable {
        var name: String
        var isTracked: Bool
        var id: String { name }
    }

    nonisolated struct Selection: Sendable, Equatable {
        var name: String
        var detail: String
        var walkMinutesText: String
        var walkHint: String
        var canDecreaseWalk: Bool
        var canIncreaseWalk: Bool
        var routes: [RouteChip]
        /// 노선을 불러오는 중이거나 실패했을 때 보여줄 문구
        var routesMessage: String?
        var isFavorite: Bool
        var actionTitle: String
    }
}
