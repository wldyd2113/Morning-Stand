import Alamofire
import Foundation
import OSLog

/// Alamofire 기반 APIClient. Session은 하나만 만들어 쓴다.
nonisolated final class AlamofireAPIClient: APIClient {
    private let session: Session
    private let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: AppConstants.Logging.networkCategory)

    init() {
        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = PolicyConstants.Network.requestTimeoutSeconds
        // 캐시는 CacheStore가 맡으므로 URLCache와 이중으로 캐시하지 않는다
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        session = Session(configuration: configuration)
    }

    func data(for endpoint: Endpoint) async throws -> Data {
        try Task.checkCancellation()
        let started = ContinuousClock.now
        let response = await session
            .request(endpoint.url, parameters: endpoint.query, encoding: URLEncoding.queryString)
            .serializingData(emptyResponseCodes: [])
            .response
        let elapsed = ContinuousClock.now - started
        let status = response.response?.statusCode ?? 0
        logger.info("[\(endpoint.api.rawValue, privacy: .public)] \(status, privacy: .public) \(elapsed.formatted(.units(allowed: [.milliseconds])), privacy: .public) \(endpoint.redactedDescription, privacy: .public)")

        if let error = response.error {
            throw Self.map(error)
        }
        switch status {
        case 200..<300:
            return response.data ?? Data()
        case 401, 403:
            throw AppError.apiKeyInvalid
        case 429:
            throw AppError.quotaExceeded
        default:
            throw AppError.server(code: "\(status)")
        }
    }

    private static func map(_ error: AFError) -> any Error {
        if error.isExplicitlyCancelledError { return CancellationError() }
        guard let urlError = error.underlyingError as? URLError else {
            if case .responseSerializationFailed = error { return AppError.decoding }
            return AppError.unknown
        }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .cannotFindHost, .cannotConnectToHost:
            return AppError.offline
        case .timedOut:
            return AppError.timeout
        case .cancelled:
            return CancellationError()
        default:
            return AppError.unknown
        }
    }
}
