import SwiftUI

/// 히어로 카드 오른쪽의 "다른 노선" 목록.
struct OtherRoutesView: View {
    let otherRoutes: StandDisplayModel.OtherRoutes
    /// 보여줄 최대 줄 수. nil이면 전부 (좁은 커버 화면에서 줄이 중간에 잘리지 않게)
    var maxRows: Int?
    /// 있으면 줄을 누를 수 있다 (반접힘 조작판에서 노선을 카운트다운 카드로 올리기)
    var onSelect: ((String) -> Void)?

    @Environment(\.standPalette) private var palette
    @Environment(\.standScale) private var scale

    private typealias Tokens = DesignTokens.Stand

    var body: some View {
        Group {
            switch otherRoutes {
            case .placeholder:
                VStack(spacing: Tokens.Spacing.skeleton * scale) {
                    ForEach(0..<Tokens.Skeleton.rowCount, id: \.self) { _ in
                        SkeletonBlock(height: Tokens.Skeleton.rowHeight * scale, cornerRadius: Tokens.Radius.skeletonRow * scale, color: palette.skeleton)
                    }
                }
                .padding(.top, Tokens.Spacing.skeleton * scale)
            case .rows(let rows, let isDimmed):
                VStack(spacing: 0) {
                    ForEach(maxRows.map { Array(rows.prefix($0)) } ?? rows) { row in
                        if let onSelect {
                            Button { onSelect(row.id) } label: { rowView(row).contentShape(Rectangle()) }
                                .buttonStyle(.plain)
                                .accessibilityHint(Text("카운트다운 카드로 올리기"))
                        } else {
                            rowView(row)
                        }
                    }
                }
                .opacity(isDimmed ? DesignTokens.Opacity.stale : 1)
            case .unavailable(let message):
                Text(message)
                    .font(.system(size: Tokens.FontSize.rowSubtitle * scale, weight: .medium))
                    .foregroundStyle(palette.secondary)
            }
        }
        .accessibilityIdentifier(AppConstants.AccessibilityID.standOtherRoutes)
    }

    private func rowView(_ row: StandDisplayModel.RouteRow) -> some View {
        HStack(spacing: Tokens.Spacing.chipContent * scale) {
            VStack(alignment: .leading, spacing: Tokens.Spacing.rowText * scale) {
                Text(row.title)
                    .font(.system(size: Tokens.FontSize.rowTitle * scale, weight: .bold))
                    .foregroundStyle(palette.text)
                Text(row.subtitle)
                    .font(.system(size: Tokens.FontSize.rowSubtitle * scale))
                    .foregroundStyle(palette.secondary)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: Tokens.Spacing.rowText * scale) {
                Text(row.etaText)
                    .font(.system(size: Tokens.FontSize.rowTitle * scale, weight: .semibold))
                    .foregroundStyle(palette.text)
                Text(row.nextText)
                    .font(.system(size: Tokens.FontSize.rowSubtitle * scale))
                    .foregroundStyle(palette.secondary)
            }
            .monospacedDigit()
        }
        .lineLimit(1)
        .padding(.vertical, Tokens.Padding.rowVertical * scale)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(palette.line)
                .frame(height: Tokens.Size.rowSeparator)
        }
        .accessibilityElement(children: .combine)
    }
}
