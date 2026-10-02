import Foundation

/// 움직임 상태 스트림. ViewModel은 CoreMotion을 모르고 이 프로토콜만 안다.
nonisolated protocol MotionStateProviding: Sendable {
    /// 상태가 바뀔 때마다 값을 낸다. 스트림을 끝내면(구독 Task 취소) 센서도 멈춘다.
    func states() -> AsyncStream<MotionState>
}

/// 고정된 상태 하나만 내는 제공자. 시뮬레이터(`-motion`)·Preview·테스트용.
nonisolated struct StaticMotionStateProvider: MotionStateProviding {
    let state: MotionState

    func states() -> AsyncStream<MotionState> {
        AsyncStream { continuation in
            continuation.yield(state)
            continuation.finish()
        }
    }
}
