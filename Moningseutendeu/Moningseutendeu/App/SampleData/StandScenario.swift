import Foundation

/// 샘플 저장소가 흉내 낼 스탠드 화면 상황. 디자인 시안의 상태(1a~1c, 4a~4d)와 1:1로 맞췄다.
/// `-standScenario <rawValue>` launch argument로 고를 수 있다.
nonisolated enum StandScenario: String, Sendable, CaseIterable {
    case relaxed
    case soon
    case now
    case missed
    case loading
    case weatherStale
    case offline
    case ended
}
