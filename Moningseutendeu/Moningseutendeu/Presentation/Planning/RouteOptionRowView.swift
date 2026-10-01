import SwiftUI

/// 이동 방법 하나: 총 소요 시간 + 구간 막대.
struct RouteOptionRowView: View {
    let option: PlanningDisplayModel.Option

    private typealias Tokens = DesignTokens.Planning

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.xxl) {
            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.xxxs) {
                Text(option.totalText)
                    .font(.system(size: Tokens.FontSize.total, weight: .bold))
                    .tracking(Tokens.Tracking.total)
                    .monospacedDigit()
                    .foregroundStyle(option.isFastest ? DesignTokens.Palette.accent : DesignTokens.Palette.textPrimary)
                Text("분")
                    .font(.system(size: Tokens.FontSize.totalUnit, weight: .semibold))
                    .foregroundStyle(DesignTokens.Palette.textSecondary)
            }
            .frame(width: Tokens.totalColumnWidth, alignment: .leading)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    // 자리가 모자라면 태그·도착 시각 대신 제목이 줄어든다
                    Text(option.title)
                        .font(.system(size: Tokens.FontSize.optionTitle, weight: .bold))
                        .minimumScaleFactor(0.8)
                    Text(option.tag)
                        .font(.system(size: Tokens.FontSize.tag, weight: .bold))
                        .foregroundStyle(option.isFastest ? DesignTokens.Palette.accent : DesignTokens.Palette.textInactive)
                        .padding(Tokens.tagPadding)
                        .background(
                            option.isFastest ? DesignTokens.Palette.accentSoftBackground : DesignTokens.Palette.surfaceElevated,
                            in: Capsule()
                        )
                        .fixedSize()
                    Spacer(minLength: 0)
                    Text(option.arrivalText)
                        .font(.system(size: Tokens.FontSize.arrival))
                        .monospacedDigit()
                        .foregroundStyle(DesignTokens.Palette.textSecondary)
                        .fixedSize()
                }
                .lineLimit(1)
                SegmentTimelineView(segments: option.segments)
            }
        }
        .padding(Tokens.optionPadding)
        .background(DesignTokens.Palette.surfaceCard, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.large, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(option.accessibilityLabel)
    }
}

/// 구간 길이에 비례한 막대와 그 아래 캡션.
struct SegmentTimelineView: View {
    let segments: [PlanningDisplayModel.Segment]

    private typealias Tokens = DesignTokens.Planning

    var body: some View {
        GeometryReader { proxy in
            let widths = Self.widths(for: segments, totalWidth: proxy.size.width)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack(spacing: Tokens.segmentSpacing) {
                    ForEach(Array(zip(segments, widths)), id: \.0.id) { segment, width in
                        SegmentSwatch(kind: segment.kind)
                            .frame(width: width, height: Tokens.segmentBarHeight)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.s, style: .continuous))
                    }
                }
                HStack(spacing: Tokens.segmentSpacing) {
                    ForEach(Array(zip(segments, widths)), id: \.0.id) { segment, width in
                        ViewThatFits(in: .horizontal) {
                            Text(segment.caption)
                            Text(segment.compactCaption)
                        }
                        .font(.system(size: Tokens.FontSize.caption))
                        .foregroundStyle(DesignTokens.Palette.textSecondary)
                        .lineLimit(1)
                        .frame(width: width, alignment: .leading)
                        .clipped()
                    }
                }
            }
        }
        .frame(height: Tokens.segmentBarHeight + DesignTokens.Spacing.sm + Tokens.segmentCaptionHeight)
    }

    /// 구간 사이 간격을 빼고 남은 너비를 분 비율로 나눈다.
    static func widths(for segments: [PlanningDisplayModel.Segment], totalWidth: CGFloat) -> [CGFloat] {
        let totalMinutes = segments.reduce(0) { $0 + $1.minutes }
        guard totalMinutes > 0 else { return segments.map { _ in 0 } }
        let spacing = Tokens.segmentSpacing * CGFloat(max(segments.count - 1, 0))
        let available = max(totalWidth - spacing, 0)
        return segments.map { available * CGFloat($0.minutes) / CGFloat(totalMinutes) }
    }
}
