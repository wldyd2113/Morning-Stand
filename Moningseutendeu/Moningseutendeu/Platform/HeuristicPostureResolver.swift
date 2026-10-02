import CoreGraphics

/// 창 모양과 움직임 상태로 자세를 추정한다.
///
/// 폴더블 iPhone의 힌지 각도를 알려주는 공개 API를 아직 확인하지 못해서(2026-10-02 기준) 두 가지 단서를 합친다.
/// | 창 모양 | 움직임 | 자세 |
/// |---|---|---|
/// | 가로로 넓음 (안쪽 화면을 펼침, iPhone Duo 951×669pt) | 무관 | `flat` |
/// | 좁음 (커버 화면 466×678pt) | 무관 | `closed` |
/// | 세로로 큼 (힌지를 가로로 두고 반쯤 접어 세움) | 놓여 있음 / 알 수 없음 | `halfOpened` |
/// | 세로로 큼 | 손에 들고 움직임 | `flat` (펼친 채 세로로 들고 보는 중) |
/// 틀릴 수 있으므로 화면에 수동 전환 버튼을 둔다.
/// TODO: 공식 힌지 API가 확인되면 `SystemPostureProvider`로 교체한다.
nonisolated enum HeuristicPostureResolver {
    static func posture(forContainerWidth width: CGFloat, height: CGFloat, motion: MotionState = .unavailable) -> DevicePosture {
        guard width > 0, height > 0 else { return .flat }
        if width > height { return .flat }
        guard width >= PolicyConstants.Posture.innerDisplayMinimumWidth else { return .closed }
        return motion == .handheld ? .flat : .halfOpened
    }
}
