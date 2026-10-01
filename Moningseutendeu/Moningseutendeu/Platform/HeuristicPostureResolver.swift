import CoreGraphics

/// 창 크기로 자세를 추정한다.
///
/// 폴더블 iPhone의 힌지 각도를 알려주는 공개 API를 아직 확인하지 못해서(2026-10-01 기준) 창 크기로 추정한다.
/// - 안쪽 화면은 펼치면 가로로 넓다 (시뮬레이터 iPhone Duo 기준 951×669pt) → `flat`
/// - 힌지를 가로로 두고 반쯤 접어 세우면 안쪽 화면이 세로가 된다 → `halfOpened`
/// - 커버 화면(466×678pt)은 너비가 좁다 → `closed`
/// 틀릴 수 있으므로 화면에 수동 전환 버튼을 둔다.
/// TODO: 공식 API가 확인되면 `SystemPostureProvider`로 교체한다.
nonisolated enum HeuristicPostureResolver {
    static func posture(forContainerWidth width: CGFloat, height: CGFloat) -> DevicePosture {
        guard width > 0, height > 0 else { return .flat }
        if width > height { return .flat }
        return width >= PolicyConstants.Posture.innerDisplayMinimumWidth ? .halfOpened : .closed
    }
}
