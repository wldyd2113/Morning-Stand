import SwiftUI

/// 큰 시계. 분이 바뀔 때만 다시 그린다 (TimelineView 범위를 시계로 한정).
struct StandClockView: View {
    let viewModel: StandViewModel

    @Environment(\.standPalette) private var palette
    @Environment(\.standScale) private var scale

    private typealias Tokens = DesignTokens.Stand

    var body: some View {
        TimelineView(.everyMinute) { context in
            let clock = viewModel.clock(at: context.date)
            let fontSize = Tokens.FontSize.clock * scale
            HStack(spacing: 0) {
                Text(clock.hour)
                Text(":").foregroundStyle(palette.accent)
                Text(clock.minute)
                    .contentTransition(.numericText())
            }
            .font(.system(size: fontSize, weight: .bold))
            .monospacedDigit()
            .tracking(Tokens.Tracking.clock * scale)
            .foregroundStyle(palette.text)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .lineHeight(fontSize: fontSize, multiple: Tokens.LineHeight.clock)
            .animation(DesignTokens.Animation.numberTransition, value: clock)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(clock.accessibilityLabel)
            .accessibilityIdentifier(AppConstants.AccessibilityID.standClock)
        }
    }
}
