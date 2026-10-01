import Foundation

/// 앱 공통 에러. 계층 밖으로 나가는 에러는 모두 이 타입으로 바꾼다.
nonisolated enum AppError: Error, Sendable, Equatable {
    case offline
    case timeout
    case server(code: String)
    case decoding
    /// 키가 없거나 등록되지 않음
    case apiKeyInvalid
    /// 서버가 알려준 일일 한도 초과
    case quotaExceeded
    /// 앱이 정한 일일 호출 한도에 걸림
    case rateLimited
    /// 즐겨찾기 정류장 등 필요한 설정이 없음
    case notConfigured
    case unknown

    init(_ error: any Error) {
        if let appError = error as? AppError {
            self = appError
        } else if error is CancellationError {
            self = .timeout
        } else {
            self = .unknown
        }
    }

    /// 사용자에게 보여줄 문구
    var userMessage: String {
        switch self {
        case .offline: String(localized: "인터넷에 연결되지 않았어요")
        case .timeout: String(localized: "응답이 늦어지고 있어요")
        case .server: String(localized: "정보를 제공하는 곳에 문제가 있어요")
        case .decoding: String(localized: "받은 정보를 읽지 못했어요")
        case .apiKeyInvalid: String(localized: "API 키가 아직 등록되지 않았어요")
        case .quotaExceeded, .rateLimited: String(localized: "오늘 조회 한도를 다 썼어요")
        case .notConfigured: String(localized: "설정에서 정류장을 추가해 주세요")
        case .unknown: String(localized: "정보를 불러오지 못했어요")
        }
    }
}
