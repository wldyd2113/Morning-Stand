import SwiftUI
import WidgetKit

/// 홈 화면(small·medium)과 잠금 화면(원형·직사각형·한 줄) 출발 위젯.
struct DepartureWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SharedConstants.departureWidgetKind, provider: DepartureTimelineProvider()) { entry in
            DepartureWidgetView(entry: entry)
        }
        .configurationDisplayName("출발 카운트다운")
        .description("지금 나가면 탈 수 있는 차와 날씨를 보여줘요.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

/// family에 따라 알맞은 레이아웃을 고른다.
struct DepartureWidgetView: View {
    let entry: DepartureWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemMedium: MediumDepartureView(entry: entry)
            case .accessoryCircular: CircularDepartureView(entry: entry)
            case .accessoryRectangular: RectangularDepartureView(entry: entry)
            case .accessoryInline: InlineDepartureView(entry: entry)
            default: SmallDepartureView(entry: entry)
            }
        }
        .containerBackground(for: .widget) {
            if family == .systemSmall || family == .systemMedium {
                SharedPalette.widgetBackground
            } else {
                AccessoryWidgetBackground()
            }
        }
    }
}

#Preview("small", as: .systemSmall) {
    DepartureWidget()
} timeline: {
    DepartureWidgetEntry.placeholder
}

#Preview("medium", as: .systemMedium) {
    DepartureWidget()
} timeline: {
    DepartureWidgetEntry.placeholder
}

#Preview("잠금 화면", as: .accessoryRectangular) {
    DepartureWidget()
} timeline: {
    DepartureWidgetEntry.placeholder
}
