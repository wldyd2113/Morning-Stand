import ActivityKit
import SwiftUI
import WidgetKit

/// 출발 카운트다운 Live Activity (잠금 화면 + Dynamic Island 컴팩트·최소·확장, 시안 3a·3c).
/// 앱이 멈춰도 `Text(timerInterval:)`과 `ProgressView(timerInterval:)`로 시스템이 숫자를 줄인다.
struct DepartureLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DepartureActivityAttributes.self) { context in
            LiveActivityLockScreenView(attributes: context.attributes, state: context.state, isStale: context.isStale)
                .activityBackgroundTint(SharedPalette.widgetBackground.opacity(0.94))
                .activitySystemActionForegroundColor(SharedPalette.textPrimary)
        } dynamicIsland: { context in
            let state = context.state
            let color = SharedPalette.urgencyColor(state.urgency)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(context.attributes.routeTitle)
                            .font(.system(size: 22, weight: .heavy))
                        Text("\(context.attributes.stopName) · 도보 \(context.attributes.walkMinutes)분")
                            .font(.system(size: 12))
                            .foregroundStyle(SharedPalette.textSecondary)
                    }
                    .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 0) {
                        CountdownText(state: state)
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundStyle(color)
                        Text(state.isNextVehicle ? "다음 차 · 뒤 출발" : "뒤 출발")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(color)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        DepartureProgressBar(state: state, color: color)
                        DepartureTimesRow(attributes: context.attributes, state: state)
                    }
                    .padding(.top, 6)
                }
            } compactLeading: {
                HStack(spacing: 5) {
                    Circle().fill(color).frame(width: 9, height: 9)
                    Text(context.attributes.routeTitle)
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                }
            } compactTrailing: {
                CountdownText(state: state)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
                    .frame(maxWidth: 52)
            } minimal: {
                CountdownText(state: state)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(color)
                    .frame(maxWidth: 40)
            }
            .keylineTint(color)
        }
    }
}

/// 잠금 화면 카드: 헤더, "N분 뒤 출발", 진행 막대, 지금·출발·도착 시각 (시안 3a 아래 카드).
struct LiveActivityLockScreenView: View {
    let attributes: DepartureActivityAttributes
    let state: DepartureActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        let color = SharedPalette.urgencyColor(state.urgency)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4).fill(SharedPalette.accent).frame(width: 14, height: 14)
                    Text("모닝스탠드")
                }
                Spacer()
                Text("\(attributes.stopName) · 도보 \(attributes.walkMinutes)분")
            }
            .font(.system(size: 13))
            .foregroundStyle(SharedPalette.textSecondary)

            HStack(alignment: .firstTextBaseline) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    CountdownText(state: state)
                        .font(.system(size: 32, weight: .heavy))
                    Text("뒤 출발")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(color)
                Spacer(minLength: 8)
                Text(attributes.routeTitle)
                    .font(.system(size: 24, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(SharedPalette.textPrimary)

            if state.isNextVehicle {
                Text("이번 차는 놓쳐서 다음 차 기준이에요")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SharedPalette.textSecondary)
            }

            DepartureProgressBar(state: state, color: color)
            DepartureTimesRow(attributes: attributes, state: state)
            if isStale {
                Text("앱을 열어 도착 정보를 새로 받아 주세요")
                    .font(.system(size: 12))
                    .foregroundStyle(SharedPalette.textSecondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}

/// 출발(놓쳤으면 다음 차 출발)까지 줄어드는 시간. 앱이 멈춰도 시스템이 그린다.
struct CountdownText: View {
    let state: DepartureActivityAttributes.ContentState

    var body: some View {
        if state.departAt > state.updatedAt {
            Text(timerInterval: state.updatedAt...state.departAt, countsDown: true, showsHours: false)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        } else {
            Text(state.urgency == .missed ? "놓침" : "지금")
        }
    }
}

/// 갱신 시각 → 출발 시각까지 채워지는 막대.
struct DepartureProgressBar: View {
    let state: DepartureActivityAttributes.ContentState
    let color: Color

    var body: some View {
        if state.departAt > state.updatedAt {
            ProgressView(timerInterval: state.updatedAt...state.departAt, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.linear)
            .tint(color)
        } else {
            Capsule().fill(SharedPalette.trackBackground).frame(height: 6)
        }
    }
}

/// "출발 7:49 · 버스 도착 7:54"
struct DepartureTimesRow: View {
    let attributes: DepartureActivityAttributes
    let state: DepartureActivityAttributes.ContentState

    var body: some View {
        HStack {
            Text("출발 \(state.departAt, format: .dateTime.hour().minute())")
            Spacer()
            Text("\(attributes.vehicleText) 도착 \(state.arrivalAt, format: .dateTime.hour().minute())")
        }
        .font(.system(size: 12))
        .monospacedDigit()
        .foregroundStyle(SharedPalette.textSecondary)
    }
}

#Preview("잠금 화면", as: .content, using: DepartureActivityAttributes(routeTitle: "1711번", stopName: "연신내역", walkMinutes: 5, vehicleText: "버스")) {
    DepartureLiveActivity()
} contentStates: {
    DepartureActivityAttributes.ContentState(updatedAt: .now, departAt: .now.addingTimeInterval(7 * 60), arrivalAt: .now.addingTimeInterval(12 * 60), isNextVehicle: false, urgency: .soon)
}

#Preview("Dynamic Island 확장", as: .dynamicIsland(.expanded), using: DepartureActivityAttributes(routeTitle: "1711번", stopName: "연신내역", walkMinutes: 5, vehicleText: "버스")) {
    DepartureLiveActivity()
} contentStates: {
    DepartureActivityAttributes.ContentState(updatedAt: .now, departAt: .now.addingTimeInterval(7 * 60), arrivalAt: .now.addingTimeInterval(12 * 60), isNextVehicle: false, urgency: .soon)
}
