import Foundation

/// 요청 하나. 경로 조각은 퍼센트 인코딩해서 붙이고, 쿼리는 APIClient가 인코딩한다.
nonisolated struct Endpoint: Sendable {
    var api: APIName
    var baseURL: URL
    var pathComponents: [String]
    var query: [String: String]
    /// 로그에서 가릴 값 (키)
    var secrets: [String]

    var url: URL {
        pathComponents.reduce(baseURL) { url, component in url.appending(path: component) }
    }

    /// 키를 가린 URL 문자열. 로그에만 쓴다.
    var redactedDescription: String {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = query.keys.sorted().map { URLQueryItem(name: $0, value: query[$0]) }
        let raw = components?.string ?? url.absoluteString
        return URLRedactor.redact(raw, secrets: secrets)
    }
}
