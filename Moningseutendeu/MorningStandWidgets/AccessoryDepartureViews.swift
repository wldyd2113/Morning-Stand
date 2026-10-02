import SwiftUI
import WidgetKit

/// 잠금 화면 원형: "7분" + 노선 (시안 3a).
struct CircularDepartureView: View {
    let entry: DepartureWidgetEntry

    var body: some View {
        let status = DepartureStatusText(entry: entry)
        VStack(spacing: 1) {
            Text(status.unit.isEmpty ? status.headline : "\(status.headline)\(status.unit)")
                .font(.system(size: 20, weight: .heavy))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(shortRoute)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
                .opacity(0.75)
        }
        .widgetAccentable()
    }

    private var shortRoute: String {
        entry.snapshot?.departure?.routeTitle ?? ""
    }
}

/// 잠금 화면 직사각형: "7분 뒤 출발 · 1711번" / "버스 12분 후 · 18시 비" (시안 3a).
struct RectangularDepartureView: View {
    let entry: DepartureWidgetEntry

    var body: some View {
        let status = DepartureStatusText(entry: entry)
        VStack(alignment: .leading, spacing: 2) {
            Text(status.summary)
                .font(.system(size: 15, weight: .bold))
                .widgetAccentable()
                .lineLimit(1)
            Text(detail)
                .font(.system(size: 13, weight: .medium))
                .opacity(0.75)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var detail: String {
        [DepartureStatusText.arrivalText(entry: entry), entry.snapshot?.weather?.rainText]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}

/// 잠금 화면 시계 위 한 줄.
struct InlineDepartureView: View {
    let entry: DepartureWidgetEntry

    var body: some View {
        Text(DepartureStatusText(entry: entry).summary)
    }
}
