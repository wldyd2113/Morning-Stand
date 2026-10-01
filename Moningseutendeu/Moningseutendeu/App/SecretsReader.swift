import Foundation
import OSLog

/// Info.plist(← Config/Secrets.xcconfig)에서 키와 서버 주소를 읽는다.
/// 값이 비어 있으면(Secrets.xcconfig가 없는 CI 등) 해당 API만 `.apiKeyInvalid`로 실패하고 앱은 계속 동작한다.
enum SecretsReader {
    private static let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: AppConstants.Logging.configurationCategory)
    private static let unresolvedPrefix = "$("

    static func serverConfiguration(bundle: Bundle = .main) -> ServerConfiguration {
        typealias Key = AppConstants.InfoPlistKey
        return ServerConfiguration(
            dataGoKrServiceKey: string(Key.dataGoKrServiceKey, in: bundle),
            seoulSubwayKey: string(Key.seoulSubwayKey, in: bundle),
            kmaBaseURL: url(Key.kmaBaseURL, in: bundle),
            airKoreaBaseURL: url(Key.airKoreaBaseURL, in: bundle),
            seoulBusBaseURL: url(Key.seoulBusBaseURL, in: bundle),
            seoulSubwayBaseURL: url(Key.seoulSubwayBaseURL, in: bundle)
        )
    }

    private static func string(_ key: String, in bundle: Bundle) -> String {
        let value = (bundle.object(forInfoDictionaryKey: key) as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !value.isEmpty, !value.hasPrefix(unresolvedPrefix) else {
            // 값 자체는 남기지 않고 어떤 항목이 비었는지만 기록한다
            logger.error("\(key, privacy: .public) 값이 비어 있어요. Config/Secrets.xcconfig를 확인하세요.")
            return ""
        }
        return value
    }

    private static func url(_ key: String, in bundle: Bundle) -> URL? {
        let value = string(key, in: bundle)
        return value.isEmpty ? nil : URL(string: value)
    }
}
