import Foundation

/// 펼침(플래닝) 화면의 탭.
nonisolated enum PlanningTab: String, Sendable, Hashable, CaseIterable {
    /// 경로 비교·루틴
    case routes
    /// 주변 정류장·집 위치·자동 처리
    case nearby
    /// 출근 기록·통계
    case history
}
