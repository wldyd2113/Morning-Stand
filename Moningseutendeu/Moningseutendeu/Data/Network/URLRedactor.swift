import Foundation

/// 로그에 키가 남지 않게 가린다.
nonisolated enum URLRedactor {
    static let mask = "***"

    static func redact(_ text: String, secrets: [String]) -> String {
        secrets
            .filter { !$0.isEmpty }
            .reduce(text) { result, secret in
                let encoded = secret.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? secret
                return result
                    .replacingOccurrences(of: secret, with: mask)
                    .replacingOccurrences(of: encoded, with: mask)
            }
    }
}
