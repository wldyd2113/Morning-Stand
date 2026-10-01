import Foundation

/// 공공데이터포털 게이트웨이 에러. JSON을 요청해도 키 오류는 이 형태(XML 또는 JSON)로 온다.
nonisolated enum DataGoKrErrorDTO {
    private static let unregisteredKeyMarkers = ["SERVICE_KEY_IS_NOT_REGISTERED", "등록되지 않은 서비스키", "SERVICE_ACCESS_DENIED"]
    private static let quotaMarkers = ["LIMITED_NUMBER_OF_SERVICE_REQUESTS"]

    /// 본문이 게이트웨이 에러면 해당 `AppError`를 돌려준다
    static func error(in data: Data) -> AppError? {
        guard let text = String(data: data.prefix(1_024), encoding: .utf8) else { return nil }
        if unregisteredKeyMarkers.contains(where: text.contains) { return .apiKeyInvalid }
        if quotaMarkers.contains(where: text.contains) { return .quotaExceeded }
        return nil
    }
}
