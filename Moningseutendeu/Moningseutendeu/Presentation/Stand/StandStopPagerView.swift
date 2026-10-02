import SwiftUI

/// 조작판 맨 위: "‹ 혜화역1번출구 · 1/4 ›". 즐겨찾기 정류장을 넘긴다.
struct StandStopPagerView: View {
    let controls: StandControlsDisplayModel
    let onPrevious: () -> Void
    let onNext: () -> Void

    @Environment(\.standPalette) private var palette
    @Environment(\.standScale) private var scale

    private typealias Tokens = DesignTokens.Stand.Controls

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs * scale) {
            if controls.canSwitchStop {
                chevron(DesignTokens.Symbol.chevronLeft, label: "이전 정류장", id: AppConstants.AccessibilityID.standPreviousStop, action: onPrevious)
            }
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxxs * scale) {
                Text(controls.stopTitle ?? String(localized: "정류장 없음"))
                    .font(.system(size: Tokens.stopTitleFont * scale, weight: .bold))
                    .foregroundStyle(palette.text)
                Text("다른 노선")
                    .font(.system(size: Tokens.stopSubtitleFont * scale))
                    .foregroundStyle(palette.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .accessibilityElement(children: .combine)
            .accessibilityHint(Text("아래 노선을 누르면 카운트다운 카드로 올라가요"))
            Spacer(minLength: 0)
            if let position = controls.stopPosition {
                Text(position)
                    .font(.system(size: Tokens.positionFont * scale, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(palette.secondary)
            }
            if controls.canSwitchStop {
                chevron(DesignTokens.Symbol.chevronRight, label: "다음 정류장", id: AppConstants.AccessibilityID.standNextStop, action: onNext)
            }
        }
    }

    private func chevron(_ symbol: String, label: LocalizedStringKey, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: Tokens.chevronSize * scale, weight: .semibold))
                .foregroundStyle(palette.text)
                .frame(width: Tokens.chevronHitSize * scale, height: Tokens.chevronHitSize * scale)
                .background(palette.card, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
        .accessibilityIdentifier(id)
    }
}
