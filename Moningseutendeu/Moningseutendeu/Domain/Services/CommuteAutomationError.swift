import Foundation

/// 출근 자동 처리를 켜지 못한 이유.
nonisolated enum CommuteAutomationError: Error, Sendable, Equatable {
    case homeNotSet
    case alwaysLocationDenied

    var userMessage: String {
        switch self {
        case .homeNotSet: String(localized: "먼저 현재 위치를 집으로 설정해 주세요")
        case .alwaysLocationDenied: String(localized: "설정에서 위치 권한을 '항상'으로 바꿔 주세요")
        }
    }
}
