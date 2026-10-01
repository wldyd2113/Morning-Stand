import SwiftUI

/// 오른쪽 아래 갱신 시각 ("12초 전 갱신"). 1초마다 이 View만 다시 그린다.
struct StandFooterView: View {
    let viewModel: StandViewModel
    let footer: StandDisplayModel.Footer

    @Environment(\.standPalette) private var palette
    @Environment(\.standScale) private var scale

    private typealias Tokens = DesignTokens.Stand

    var body: some View {
        TimelineView(.periodic(from: viewModel.now, by: PolicyConstants.Stand.footerRefreshIntervalSeconds)) { context in
            HStack(spacing: Tokens.Spacing.footerContent * scale) {
                Circle()
                    .fill(dotColor)
                    .frame(width: Tokens.Size.footerDot * scale, height: Tokens.Size.footerDot * scale)
                Text(viewModel.footerText(footer, at: context.date))
                    .monospacedDigit()
            }
            .font(.system(size: Tokens.FontSize.footer * scale, weight: .medium))
            .foregroundStyle(palette.dim)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var dotColor: Color {
        guard footer.isLive else { return palette.dim }
        return palette.theme == .night ? palette.secondary : DesignTokens.Palette.liveIndicator
    }
}
