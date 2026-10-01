import Foundation
import Observation

/// 알림 설정 (출발·놓침·우산·미세먼지)과 알림 미리보기 문구.
@MainActor @Observable
final class NotificationSettingsViewModel {
    var isDepartureAlertOn = true
    var isMissAlertOn = true
    var isUmbrellaAlertOn = true
    var isDustAlertOn = false
    var leadMinutes = PolicyConstants.Notification.defaultDepartureLeadMinutes

    let leadOptions = PolicyConstants.Notification.departureLeadOptionsMinutes

    @ObservationIgnored private let sample: PreviewContext
    @ObservationIgnored private let dateProvider: any DateProvider
    @ObservationIgnored private let calendar: Calendar

    /// 미리보기 문구에 쓸 기본 경로 정보
    struct PreviewContext {
        var routeTitle: String
        var vehicleText: String
        var walkMinutes: Int
        var rainStartHour: Int?
    }

    init(preview: PreviewContext, dateProvider: any DateProvider, calendar: Calendar = .seoul) {
        self.sample = preview
        self.dateProvider = dateProvider
        self.calendar = calendar
    }

    var rainThresholdText: String {
        String(localized: "\(PolicyConstants.Notification.rainProbabilityThresholdPercent)% 이상")
    }

    func leadText(_ minutes: Int) -> String {
        String(localized: "\(minutes)분")
    }

    var previewTitle: String {
        isDepartureAlertOn ? String(localized: "\(leadMinutes)분 뒤 출발하세요") : String(localized: "오늘 날씨")
    }

    var previewBody: String {
        let rain = isUmbrellaAlertOn ? rainText : nil
        guard isDepartureAlertOn else {
            return rain ?? String(localized: "알림이 꺼져 있어요.")
        }
        let arrival = String(localized: "\(sample.routeTitle) \(sample.vehicleText) \(leadMinutes + sample.walkMinutes)분 후 도착")
        guard let rain else { return arrival }
        return "\(arrival) · \(rain)"
    }

    private var rainText: String? {
        guard let hour = sample.rainStartHour else { return nil }
        let hourText = DisplayFormatter.hourText(hour: hour, on: dateProvider.now, calendar: calendar)
        return String(localized: "\(hourText)부터 비, 우산 챙기세요.")
    }
}
