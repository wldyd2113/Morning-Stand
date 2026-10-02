import SwiftUI
import WidgetKit

/// 홈 small: 노선, 큰 분 숫자, 날씨 한 줄 (시안 3b 왼쪽).
struct SmallDepartureView: View {
    let entry: DepartureWidgetEntry

    var body: some View {
        let status = DepartureStatusText(entry: entry)
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(entry.snapshot?.departure?.routeTitle ?? String(localized: "모닝스탠드"))
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                Spacer(minLength: 4)
                Circle().fill(status.color).frame(width: 8, height: 8)
            }
            DepartureHeadline(status: status)
                .padding(.top, 10)
            Text(status.caption)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .padding(.top, 2)
            Spacer(minLength: 0)
            WidgetFootnote(entry: entry, text: weatherLine)
        }
        .foregroundStyle(SharedPalette.textPrimary)
        .opacity(entry.isStale ? 0.6 : 1)
    }

    private var weatherLine: String? {
        guard let weather = entry.snapshot?.weather else { return DepartureStatusText.arrivalText(entry: entry) }
        return [weather.temperatureText, weather.rainText].compactMap { $0 }.joined(separator: " · ")
    }
}

/// "7분" 큰 숫자. 숫자가 아니면 조금 작게 그린다.
struct DepartureHeadline: View {
    let status: DepartureStatusText

    var body: some View {
        let isNumber = Int(status.headline) != nil
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(status.headline)
                .font(.system(size: isNumber ? 56 : 36, weight: .heavy))
                .tracking(-2)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
            if !status.unit.isEmpty {
                Text(status.unit).font(.system(size: 20, weight: .bold))
            }
        }
        .foregroundStyle(status.color)
        .lineLimit(1)
    }
}

/// 아래 회색 한 줄. 스냅샷이 오래됐으면 "N분 전 정보"를 붙인다.
struct WidgetFootnote: View {
    let entry: DepartureWidgetEntry
    let text: String?

    var body: some View {
        Group {
            if entry.isStale, let generatedAt = entry.snapshot?.generatedAt {
                Text("\(generatedAt, style: .relative) 전 정보")
            } else if let text {
                Text(text)
            }
        }
        .font(.system(size: 13))
        .foregroundStyle(SharedPalette.textSecondary)
        .lineLimit(1)
    }
}
