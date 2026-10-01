import Foundation

/// 폴더블 기기의 접힘 자세.
nonisolated enum DevicePosture: String, Sendable, Equatable, CaseIterable {
    case closed
    case halfOpened
    case flat
}
