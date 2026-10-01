import SwiftUI

/// "몇 분 뒤 출발" 카드. 단계(여유/곧 출발/지금 출발/놓침)에 따라 색이 바뀐다.
struct DepartureHeroView: View {
    let hero: StandDisplayModel.Hero

    @Environment(\.standPalette) private var palette
    @Environment(\.standScale) private var scale

    private typealias Tokens = DesignTokens.Stand

    var body: some View {
        Group {
            switch hero {
            case .placeholder:
                placeholder
            case .departure(let departure):
                departureCard(departure)
            case .notice(let notice):
                noticeCard(notice)
            }
        }
        .accessibilityIdentifier(AppConstants.AccessibilityID.standHero)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Tokens.Radius.hero * scale, style: .continuous)
    }

    // MARK: - 로딩

    private var placeholder: some View {
        VStack(alignment: .leading, spacing: 0) {
            skeleton(Tokens.Skeleton.heroBadge, radius: Tokens.Skeleton.heroBadge.height / 2)
            Spacer(minLength: 0)
            skeleton(Tokens.Skeleton.heroNumber, radius: Tokens.Radius.skeletonBlock)
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm * scale) {
                skeleton(Tokens.Skeleton.heroRoute, radius: Tokens.Radius.skeletonText)
                skeleton(Tokens.Skeleton.heroDetail, radius: Tokens.Radius.skeletonText)
            }
        }
        .padding(Tokens.Padding.hero.scaled(scale))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(palette.card, in: cardShape)
    }

    private func skeleton(_ size: CGSize, radius: CGFloat) -> some View {
        SkeletonBlock(width: size.width * scale, height: size.height * scale, cornerRadius: radius * scale, color: palette.skeleton)
    }

    // MARK: - 출발 카운트다운

    private func departureCard(_ departure: StandDisplayModel.DepartureHero) -> some View {
        let colors = palette.heroColors(for: departure.urgency)
        let headlineSize = (departure.isNumericHeadline ? Tokens.FontSize.heroNumber : Tokens.FontSize.heroWord) * scale
        let unitSize = Tokens.FontSize.heroUnit * scale

        return VStack(alignment: .leading, spacing: 0) {
            badge(departure.badge, background: colors.badge)
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: Tokens.Spacing.heroHeadlineToUnit * scale) {
                Text(departure.headline)
                    .font(.system(size: headlineSize, weight: .heavy))
                    .monospacedDigit()
                    .tracking(Tokens.Tracking.heroHeadline * scale)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())
                    .lineHeight(fontSize: headlineSize, multiple: Tokens.LineHeight.heroHeadline)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(departure.unitLines, id: \.self) { line in
                        Text(line).lineHeight(fontSize: unitSize, multiple: Tokens.LineHeight.heroUnit)
                    }
                }
                .font(.system(size: unitSize, weight: .bold))
                .tracking(Tokens.Tracking.heroUnit * scale)
                .lineLimit(1)
                .fixedSize()
            }
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: Tokens.Spacing.heroFooter * scale) {
                Text(departure.routeTitle)
                    .font(.system(size: Tokens.FontSize.heroRoute * scale, weight: .heavy))
                Text(departure.detail)
                    .font(.system(size: Tokens.FontSize.heroDetail * scale, weight: .semibold))
                    .opacity(DesignTokens.Opacity.secondaryText)
                    .minimumScaleFactor(0.7)
            }
            .lineLimit(1)
        }
        .foregroundStyle(colors.foreground)
        .padding(Tokens.Padding.hero.scaled(scale))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(colors.background, in: cardShape)
        .animation(DesignTokens.Animation.numberTransition, value: departure)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(departure.accessibilityLabel)
    }

    // MARK: - 오프라인·운행 종료

    private func noticeCard(_ notice: StandDisplayModel.NoticeHero) -> some View {
        let headlineSize = Tokens.FontSize.noticeHeadline * scale
        let isEnded = notice.style != .offline

        return VStack(alignment: .leading, spacing: 0) {
            badge(notice.badge, background: isEnded ? DesignTokens.Hero.badgeOnEnded : palette.cardStrong)
            Spacer(minLength: 0)
            Text(notice.headline)
                .font(.system(size: headlineSize, weight: .heavy))
                .tracking(Tokens.Tracking.noticeHeadline * scale)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .lineHeight(fontSize: headlineSize, multiple: Tokens.LineHeight.noticeHeadline)
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: Tokens.Spacing.heroFooter * scale) {
                Text(notice.title)
                    .font(.system(size: (isEnded ? Tokens.FontSize.heroRoute : Tokens.FontSize.noticeTitle) * scale, weight: isEnded ? .heavy : .bold))
                Text(notice.detail)
                    .font(.system(size: Tokens.FontSize.heroDetail * scale, weight: .semibold))
                    .foregroundStyle(palette.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .foregroundStyle(palette.text)
        .padding(Tokens.Padding.hero.scaled(scale))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(isEnded ? palette.cardStrong : palette.card, in: cardShape)
        .overlay {
            if !isEnded {
                cardShape.strokeBorder(palette.cardStrong, lineWidth: Tokens.Size.noticeBorder * scale)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func badge(_ text: String, background: Color) -> some View {
        Text(text)
            .font(.system(size: Tokens.FontSize.heroBadge * scale, weight: .bold))
            .lineLimit(1)
            .padding(Tokens.Padding.badge.scaled(scale))
            .background(background, in: Capsule())
    }
}
