import Foundation

/// 가속도·회전 세기로 "놓여 있음 / 손에 듦"을 판단한다. 센서 없이 테스트할 수 있는 순수 로직.
///
/// - 놓여 있음: 움직임이 아주 작은 상태가 `restingDurationSeconds` 동안 이어짐
/// - 손에 듦: 뚜렷한 움직임이 `handheldDurationSeconds` 동안 이어짐 (화면을 한 번 톡 치는 정도로는 바뀌지 않게)
/// - 그 사이 값: 지금 상태를 유지한다
/// 기준값은 실제 기기에서 다시 맞춰야 한다 (PolicyConstants.Posture).
nonisolated struct MotionClassifier: Sendable {
    private(set) var state: MotionState = .unavailable
    private var calmSince: TimeInterval?
    private var activeSince: TimeInterval?

    /// 새 측정값을 반영하고, 상태가 바뀌었으면 새 상태를 돌려준다.
    /// - Parameters:
    ///   - acceleration: 사용자 가속도 크기 (g)
    ///   - rotationRate: 회전 속도 크기 (rad/s)
    ///   - time: 측정 시각 (초, 단조 증가)
    mutating func update(acceleration: Double, rotationRate: Double, at time: TimeInterval) -> MotionState? {
        typealias Policy = PolicyConstants.Posture
        let isCalm = acceleration <= Policy.restingAccelerationG && rotationRate <= Policy.restingRotationRadiansPerSecond
        let isActive = acceleration >= Policy.handheldAccelerationG || rotationRate >= Policy.handheldRotationRadiansPerSecond

        var next = state
        if isCalm {
            activeSince = nil
            let start = calmSince ?? time
            calmSince = start
            if time - start >= Policy.restingDurationSeconds { next = .resting }
        } else if isActive {
            calmSince = nil
            let start = activeSince ?? time
            activeSince = start
            if time - start >= Policy.handheldDurationSeconds { next = .handheld }
        } else {
            calmSince = nil
            activeSince = nil
        }

        guard next != state else { return nil }
        state = next
        return next
    }
}
