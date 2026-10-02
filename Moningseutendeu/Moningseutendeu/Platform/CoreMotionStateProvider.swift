import CoreMotion
import Foundation
import Synchronization

/// CoreMotion으로 "놓여 있음 / 손에 듦"을 판단한다. 기기 움직임(가속도·회전) 읽기는 권한이 필요 없다.
/// 센서가 없으면(시뮬레이터) `.unavailable`을 한 번 내고 끝난다.
nonisolated struct CoreMotionStateProvider: MotionStateProviding {
    func states() -> AsyncStream<MotionState> {
        AsyncStream { continuation in
            let session = MotionSession(continuation: continuation)
            continuation.onTermination = { _ in session.stop() }
            session.start()
        }
    }
}

/// 스트림 하나가 쓰는 센서 세션.
/// CMMotionManager와 분류기 상태는 Sendable이 아니라서 Mutex 안에서만 다룬다.
nonisolated final class MotionSession: Sendable {
    private struct State {
        var manager: CMMotionManager?
        var classifier = MotionClassifier()
    }

    private let state = Mutex(State())
    private let continuation: AsyncStream<MotionState>.Continuation
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = AppConstants.Logging.subsystem + ".motion"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    init(continuation: AsyncStream<MotionState>.Continuation) {
        self.continuation = continuation
    }

    func start() {
        let isAvailable = state.withLock { state -> Bool in
            let manager = CMMotionManager()
            guard manager.isDeviceMotionAvailable else { return false }
            manager.deviceMotionUpdateInterval = PolicyConstants.Posture.motionSampleIntervalSeconds
            manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
                guard let self, let motion else { return }
                let acceleration = motion.userAcceleration
                let rotation = motion.rotationRate
                self.handle(
                    acceleration: (acceleration.x * acceleration.x + acceleration.y * acceleration.y + acceleration.z * acceleration.z).squareRoot(),
                    rotationRate: (rotation.x * rotation.x + rotation.y * rotation.y + rotation.z * rotation.z).squareRoot(),
                    time: motion.timestamp
                )
            }
            state.manager = manager
            return true
        }
        guard isAvailable else {
            continuation.yield(.unavailable)
            continuation.finish()
            return
        }
    }

    func stop() {
        state.withLock { state in
            state.manager?.stopDeviceMotionUpdates()
            state.manager = nil
        }
    }

    private func handle(acceleration: Double, rotationRate: Double, time: TimeInterval) {
        let changed = state.withLock { $0.classifier.update(acceleration: acceleration, rotationRate: rotationRate, at: time) }
        if let changed { continuation.yield(changed) }
    }
}
