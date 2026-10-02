import SwiftUI
import WidgetKit

/// 홈 medium: 왼쪽 출발, 오른쪽 날씨·미세먼지·우산 (시안 3b 오른쪽).
struct MediumDepartureView: View {
    let entry: DepartureWidgetEntry

    var body: some View {
        let status = DepartureStatusText(entry: entry)
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(entry.snapshot?.departure?.routeTitle ?? String(localized: "모닝스탠드"))
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Circle().fill(status.color).frame(width: 8, height: 8)
                }
                DepartureHeadline(status: status).padding(.top, 10)
                Text(status.caption)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .padding(.top, 2)
                Spacer(minLength: 0)
                WidgetFootnote(entry: entry, text: arrivalLine)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle().fill(SharedPalette.divider).frame(width: 1)

            weatherColumn
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(SharedPalette.textPrimary)
        .opacity(entry.isStale ? 0.6 : 1)
    }

    private var arrivalLine: String? {
        guard let departure = entry.snapshot?.departure else { return nil }
        return [DepartureStatusText.arrivalText(entry: entry), String(localized: "도보 \(departure.walkMinutes)분")]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    @ViewBuilder
    private var weatherColumn: some View {
        if let weather = entry.snapshot?.weather {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: weather.symbolName)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 22))
                    Text(weather.temperatureText)
                        .font(.system(size: 40, weight: .semibold))
                        .tracking(-1)
                        .monospacedDigit()
                }
                Text("\(weather.conditionText) · \(weather.rangeText)")
                    .font(.system(size: 12))
                    .foregroundStyle(SharedPalette.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 6)
                HStack(spacing: 10) {
                    airChip(weather.pm10Text, level: weather.pm10Level)
                    airChip(weather.pm25Text, level: weather.pm25Level)
                }
                .padding(.top, 8)
                Spacer(minLength: 0)
                if let rain = weather.rainText {
                    Text(String(localized: "\(rain) · 우산"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SharedPalette.accent)
                        .lineLimit(1)
                }
            }
        } else {
            Text("날씨 정보 없음")
                .font(.system(size: 13))
                .foregroundStyle(SharedPalette.textSecondary)
        }
    }

    private func airChip(_ text: String, level: DashboardSnapshot.AirLevel) -> some View {
        HStack(spacing: 4) {
            Circle().fill(SharedPalette.airColor(level)).frame(width: 7, height: 7)
            Text(text)
        }
        .font(.system(size: 12, weight: .semibold))
        .lineLimit(1)
        .fixedSize()
    }
}
