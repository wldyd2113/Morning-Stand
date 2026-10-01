import CoreGraphics
import Foundation
import Observation

/// 자세(posture)에 따라 스탠드/플래닝 화면을 고른다. 추정이 틀릴 수 있어서 수동 전환을 우선한다.
@MainActor @Observable
final class RootViewModel {
    private(set) var detectedPosture: DevicePosture = .flat
    private(set) var manualMode: ScreenMode?
    var isSettingsPresented = false

    @ObservationIgnored private let forcedPosture: DevicePosture?

    init(forcedPosture: DevicePosture? = nil) {
        self.forcedPosture = forcedPosture
        if let forcedPosture { detectedPosture = forcedPosture }
    }

    var screenMode: ScreenMode {
        manualMode ?? ScreenMode(posture: detectedPosture)
    }

    /// 창 크기가 바뀌면 자세를 다시 추정한다. 자세가 바뀌면 수동 선택은 풀어서 새 자세를 따른다.
    func updateContainerSize(_ size: CGSize) {
        guard forcedPosture == nil else { return }
        let posture = HeuristicPostureResolver.posture(forContainerWidth: size.width, height: size.height)
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
