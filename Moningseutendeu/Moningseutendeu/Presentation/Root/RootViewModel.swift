import CoreGraphics
import Foundation
import Observation

/// 자세(posture)에 따라 스탠드/플래닝 화면을 고른다. 추정이 틀릴 수 있어서 수동 전환을 우선한다.
///
/// 자세는 창 모양과 움직임 상태(CoreMotion)로 추정하고(`candidatePosture`),
/// 잠깐 그대로일 때만 확정한다(`detectedPosture`). 접는 도중 화면이 여러 번 바뀌지 않게 하기 위해서다.
@MainActor @Observable
final class RootViewModel {
    /// 확정된 자세
    private(set) var detectedPosture: DevicePosture = .flat
    private(set) var motionState: MotionState = .unavailable
    private(set) var containerSize: CGSize = .zero
    private(set) var manualMode: ScreenMode?
    var isSettingsPresented = false
    /// 펼침 화면에서 고른 탭. 스탠드로 갔다 와도 유지한다
    var planningTab: PlanningTab = .routes

    @ObservationIgnored private let forcedPosture: DevicePosture?
    @ObservationIgnored private let motionProvider: any MotionStateProviding
    @ObservationIgnored private let clock: any Clock<Duration>
    /// 처음 한 번은 기다리지 않고 바로 확정한다 (실행 직후 화면이 한 번 바뀌는 것 방지)
    @ObservationIgnored private var hasSettled = false

    init(
        forcedPosture: DevicePosture? = nil,
        initialPlanningTab: PlanningTab = .routes,
        motionProvider: any MotionStateProviding = StaticMotionStateProvider(state: .unavailable),
        clock: any Clock<Duration> = ContinuousClock()
    ) {
        self.forcedPosture = forcedPosture
        self.planningTab = initialPlanningTab
        self.motionProvider = motionProvider
        self.clock = clock
        if let forcedPosture {
            detectedPosture = forcedPosture
            hasSettled = true
        }
    }

    /// 지금 창 모양과 움직임으로 추정한 자세 (아직 확정 전)
    var candidatePosture: DevicePosture {
        forcedPosture ?? HeuristicPostureResolver.posture(
            forContainerWidth: containerSize.width,
            height: containerSize.height,
            motion: motionState
        )
    }

    var screenMode: ScreenMode {
        manualMode ?? ScreenMode(posture: detectedPosture)
    }

    /// 창 크기가 바뀌면 추정을 다시 한다. 처음 크기를 받으면 바로 확정한다.
    func updateContainerSize(_ size: CGSize) {
        guard forcedPosture == nil else { return }
        containerSize = size
        if !hasSettled { commit(candidatePosture) }
    }

    /// 움직임 상태를 계속 받는다. View의 `.task`에서 부르면 화면을 떠날 때 센서도 멈춘다.
    func observeMotion() async {
        guard forcedPosture == nil else { return }
        for await state in motionProvider.states() {
            motionState = state
        }
    }

    /// 추정한 자세가 잠깐 그대로면 확정한다. View의 `.task(id: candidatePosture)`에서 부르므로
    /// 그 사이 추정이 바뀌면 이 호출은 취소되고 새 값으로 다시 기다린다.
    func settlePosture() async {
        let candidate = candidatePosture
        guard candidate != detectedPosture else { return }
        do {
            try await clock.sleep(for: PolicyConstants.Posture.settleDelay)
        } catch {
            return
        }
        guard candidate == candidatePosture else { return }
        commit(candidate)
    }

    /// 자세가 바뀌면 수동 선택은 풀어서 새 자세를 따른다.
    private func commit(_ posture: DevicePosture) {
        hasSettled = true
        guard posture != detectedPosture else { return }
        detectedPosture = posture
        manualMode = nil
    }

    func toggleMode() {
        manualMode = screenMode == .stand ? .planning : .stand
    }

    func openSettings() {
        isSettingsPresented = true
    }
}
