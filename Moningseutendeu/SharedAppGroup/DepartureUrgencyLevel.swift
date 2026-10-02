import Foundation

/// 위젯·Live Activity에 넘기는 출발 단계. 앱이 도메인 규칙으로 계산해서 넣고, 위젯은 그리기만 한다.
nonisolated enum DepartureUrgencyLevel: String, Codable, Sendable, Hashable {
    case relaxed
    case soon
    case now
    case missed
}
