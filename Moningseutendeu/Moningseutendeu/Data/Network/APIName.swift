import Foundation

/// 호출 한도와 로그를 API별로 나누기 위한 이름.
nonisolated enum APIName: String, Sendable, CaseIterable {
    case kma
    case airKorea
    case seoulBus
    case seoulSubway

    /// 앱이 스스로 지키는 일일 호출 한도
    var dailyLimit: Int {
        switch self {
        case .kma: PolicyConstants.DailyLimit.kma
        case .airKorea: PolicyConstants.DailyLimit.airKorea
        case .seoulBus: PolicyConstants.DailyLimit.seoulBus
        case .seoulSubway: PolicyConstants.DailyLimit.seoulSubway
        }
    }
}
