import Foundation
import OSLog

/// API별 일일 호출 한도. 날짜는 KST 기준이고, 앱을 다시 켜도 유지되도록 UserDefaults에 센다.
actor RateLimiter {
    private let dateProvider: any DateProvider
    private let calendar: Calendar
    private let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: AppConstants.Logging.networkCategory)

    init(dateProvider: any DateProvider, calendar: Calendar = .seoul) {
        self.dateProvider = dateProvider
        self.calendar = calendar
    }

    /// 호출 한 건을 쓴다. 한도를 넘으면 `.rateLimited`
    func acquire(_ api: APIName) throws {
        let key = counterKey(api)
        let count = UserDefaults.standard.integer(forKey: key)
        guard count < api.dailyLimit else {
            logger.warning("[\(api.rawValue, privacy: .public)] 일일 한도 \(api.dailyLimit, privacy: .public)건 도달")
            throw AppError.rateLimited
        }
        UserDefaults.standard.set(count + 1, forKey: key)
    }

    /// 서버가 한도 초과를 알려주면 그날은 더 부르지 않는다
    func exhaust(_ api: APIName) {
        UserDefaults.standard.set(api.dailyLimit, forKey: counterKey(api))
    }

    func remaining(_ api: APIName) -> Int {
        max(api.dailyLimit - UserDefaults.standard.integer(forKey: counterKey(api)), 0)
    }

    private func counterKey(_ api: APIName) -> String {
        AppConstants.UserDefaultsKey.rateLimitPrefix + api.rawValue + "." + KSTDateParser.compactDate(dateProvider.now, calendar: calendar)
    }
}
