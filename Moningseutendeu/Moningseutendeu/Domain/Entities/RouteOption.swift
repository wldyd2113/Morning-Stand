import Foundation

/// 한 경로 안의 이동 방법 하나 (예: 1711번 직행, 3호선 → 5호선).
nonisolated struct RouteOption: Sendable, Equatable, Identifiable, Codable {
    var id: String
    var title: String
    /// "환승 없음", "덜 붐빔" 같은 보조 설명
    var note: String
    var segments: [RouteSegment]
    /// 사용자가 입력한 값. 편집 화면에서 다시 불러올 때 쓴다 (샘플 데이터는 없음)
    var plan: RoutePlan? = nil

    var totalMinutes: Int { segments.reduce(0) { $0 + $1.minutes } }
}
