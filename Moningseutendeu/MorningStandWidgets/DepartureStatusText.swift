import SwiftUI

/// 출발 단계 → 위젯 문구. 큰 글자(headline)와 그 옆 단위(unit), 한 줄 요약(summary)을 만든다.
struct DepartureStatusText {
    let headline: String
    let unit: String
    let caption: String
    let summary: String
    let color: Color

    init(entry: DepartureWidgetEntry) {
        let departure = entry.snapshot?.departure
        guard let departure else {
            headline = "—"
            unit = ""
            caption = String(localized: "앱에서 정류장을 추가하세요")
            summary = caption
            color = SharedPalette.textSecondary
            return
        }
        guard let moment = entry.moment else {
            headline = departure.statusText ?? String(localized: "정보 없음")
            unit = ""
            caption = departure.routeTitle
            summary = "\(departure.routeTitle) \(headline)"
            color = SharedPalette.textSecondary
            return
        }
        color = SharedPalette.urgencyColor(moment.urgency)
        switch moment.urgency {
        case .relaxed, .soon:
            headline = "\(moment.minutesUntilDeparture)"
            unit = String(localized: "분")
            caption = String(localized: "뒤 출발")
            summary = String(localized: "\(departure.routeTitle) \(moment.minutesUntilDeparture)분 뒤 출발")
        case .now:
            headline = String(localized: "지금")
            unit = ""
            caption = String(localized: "출발하세요")
            summary = String(localized: "\(departure.routeTitle) 지금 출발하세요")
        case .missed:
            headline = String(localized: "놓침")
            unit = ""
            if let next = moment.nextDepartureMinutes {
                caption = String(localized: "다음 차 \(next)분 뒤")
                summary = String(localized: "\(departure.routeTitle) 다음 차 \(next)분 뒤 출발")
            } else {
                caption = String(localized: "다음 차 정보 없음")
                summary = String(localized: "\(departure.routeTitle) 놓침")
            }
        }
    }

    /// "버스 12분 후" / 상태 문구
    static func arrivalText(entry: DepartureWidgetEntry) -> String? {
        guard let departure = entry.snapshot?.departure else { return nil }
        guard let minutes = entry.minutesUntilArrival else { return departure.statusText }
        return minutes == 0
            ? String(localized: "\(departure.vehicleText) 곧 도착")
            : String(localized: "\(departure.vehicleText) \(minutes)분 후")
    }
}
