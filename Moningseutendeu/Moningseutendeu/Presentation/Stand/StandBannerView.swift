import SwiftUI

/// 위 패널 아래줄: 비 예보, 날씨 지연, 오프라인 안내.
struct StandBannerView: View {
    let banner: StandDisplayModel.Banner

    @Environment(\.standPalette) private var palette
    @Environment(\.standScale) private var scale

    private typealias Tokens = DesignTokens.Stand

    var body: some View {
        switch banner {
        case .none:
            EmptyView()
        case .placeholder:
            SkeletonBlock(height: Tokens.Skeleton.bannerHeight * scale, cornerRadius: Tokens.Radius.banner * scale, color: palette.skeleton)
        case .rain(let message):
            HStack(spacing: Tokens.Spacing.banner * scale) {
                Image(systemName: DesignTokens.Symbol.umbrella)
                    .font(.system(size: Tokens.Size.bannerIcon * scale, weight: .bold))
                    .accessibilityHidden(true)
                Text(message)
            }
            .font(.system(size: Tokens.FontSize.banner * scale, weight: .bold))
            .foregroundStyle(palette.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(Tokens.Padding.rainBanner.scaled(scale))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.accentBackground, in: bannerShape)
        case .notice(let notice):
            HStack(spacing: Tokens.Spacing.noticeBanner * scale) {
                badge(notice)
                Text(notice.message)
                    .font(.system(size: Tokens.FontSize.bannerMessage * scale, weight: .medium))
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(Tokens.Padding.noticeBanner.scaled(scale))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.card, in: bannerShape)
            .accessibilityElement(children: .combine)
        }
    }

    private var bannerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Tokens.Radius.banner * scale, style: .continuous)
    }

    @ViewBuilder
    private func badge(_ notice: StandDisplayModel.Notice) -> some View {
        let text = Text(notice.badge)
            .font(.system(size: Tokens.FontSize.bannerBadge * scale, weight: .bold))
            .lineLimit(1)
            .fixedSize()
            .padding(Tokens.Padding.badge.scaled(scale))
        switch notice.style {
        case .stale:
            text
                .foregroundStyle(palette.accent)
                .overlay(Capsule().strokeBorder(palette.accent, lineWidth: Tokens.Size.noticeBorder * scale))
        case .offline:
            text
                .foregroundStyle(palette.text)
                .background(palette.cardStrong, in: Capsule())
        }
    }
}
