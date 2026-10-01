import Foundation

/// 서버 주소와 키. App의 `SecretsReader`가 Info.plist에서 읽어 만든다. 비어 있으면 해당 API는 `.apiKeyInvalid`로 실패한다.
nonisolated struct ServerConfiguration: Sendable {
    var dataGoKrServiceKey: String
    var seoulSubwayKey: String
    var kmaBaseURL: URL?
    var airKoreaBaseURL: URL?
    var seoulBusBaseURL: URL?
    var seoulSubwayBaseURL: URL?

    /// 모든 키를 로그 마스킹 대상으로 돌려준다
    var secrets: [String] { [dataGoKrServiceKey, seoulSubwayKey] }

    static let empty = ServerConfiguration(dataGoKrServiceKey: "", seoulSubwayKey: "")
}
