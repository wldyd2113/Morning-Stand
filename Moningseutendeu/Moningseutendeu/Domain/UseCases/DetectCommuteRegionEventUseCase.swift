import Foundation

/// 지역 안/밖 상태 변화를 출근 이벤트로 바꾼다.
///
/// | 지역 | 이전 | 지금 | 이벤트 |
/// |---|---|---|---|
/// | 집 | 안 | 밖 | 집을 나섬 |
/// | 집 | 모름·밖 | 밖 | 없음 (감시를 켤 때 이미 밖이었던 경우를 거른다) |
/// | 정류장 | 모름·밖 | 안 | 정류장 근처 도착 |
nonisolated struct DetectCommuteRegionEventUseCase: Sendable {
    func callAsFunction(region: CommuteRegion, previous: RegionPresence?, current: RegionPresence, at date: Date) -> CommuteRegionEvent? {
        switch (region, previous, current) {
        case (.home, .inside?, .outside): .leftHome(at: date)
        case (.stop, .outside?, .inside), (.stop, nil, .inside): .nearStop(at: date)
        default: nil
        }
    }
}
