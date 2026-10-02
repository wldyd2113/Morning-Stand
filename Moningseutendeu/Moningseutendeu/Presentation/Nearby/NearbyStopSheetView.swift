import SwiftUI

/// 지도에서 고른 정류장 시트: 도보 시간, 노선별 도착 정보, 즐겨찾기 저장.
struct NearbyStopSheetView: View {
    let viewModel: NearbyStopsViewModel

    private typealias Tokens = DesignTokens.Nearby
    private typealias SettingsTokens = DesignTokens.Settings

    var body: some View {
        if let selection = viewModel.display.selection {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.m) {
                    header(selection)
                    walk(selection)
                    arrivals(selection.arrivals)
                    if let error = selection.errorMessage {
                        Text(error)
                            .font(.system(size: SettingsTokens.FontSize.footnote, weight: .semibold))
                            .foregroundStyle(DesignTokens.Palette.error)
                    }
                    favoriteButton(selection)
                }
                .padding(SettingsTokens.screenPadding)
            }
            .foregroundStyle(DesignTokens.Palette.textPrimary)
            .tint(DesignTokens.Palette.accent)
        }
    }

    private func header(_ selection: NearbyDisplayModel.Selection) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxxs) {
                Text(selection.name)
                    .font(.system(size: SettingsTokens.FontSize.sheetTitle, weight: .bold))
                Text(selection.detail)
                    .font(.system(size: SettingsTokens.FontSize.subheadline))
                    .foregroundStyle(DesignTokens.Palette.textSecondary)
            }
            Spacer()
            Button(action: viewModel.clearSelection) {
                Image(systemName: DesignTokens.Symbol.close)
                    .font(.system(size: SettingsTokens.FontSize.sheetTitle))
                    .foregroundStyle(DesignTokens.Palette.textTertiary)
            }
            .accessibilityLabel(Text("닫기"))
        }
    }

    private func walk(_ selection: NearbyDisplayModel.Selection) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.s) {
            Image(systemName: DesignTokens.Symbol.walk)
                .foregroundStyle(DesignTokens.Palette.textSecondary)
                .accessibilityHidden(true)
            Text(selection.walkMinutesText)
                .font(.system(size: Tokens.FontSize.walkValue, weight: .bold))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(selection.walkSourceText)
                .font(.system(size: SettingsTokens.FontSize.footnote))
                .foregroundStyle(DesignTokens.Palette.textTertiary)
            if selection.isCalculatingWalk { ProgressView() }
        }
        .animation(DesignTokens.Animation.numberTransition, value: selection.walkMinutesText)
    }

    private func arrivals(_ arrivals: NearbyDisplayModel.Arrivals) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
            HStack {
                Text("도착 정보")
                    .font(.system(size: Tokens.FontSize.arrivalTitle, weight: .bold))
                if case .rows(_, let updatedText, _) = arrivals {
                    Text(updatedText)
                        .font(.system(size: Tokens.FontSize.arrivalDetail))
                        .foregroundStyle(DesignTokens.Palette.textTertiary)
                }
                Spacer()
                Button {
                    Task { await viewModel.refreshArrivals() }
                } label: {
                    Image(systemName: DesignTokens.Symbol.refresh)
                        .font(.system(size: SettingsTokens.FontSize.callout, weight: .semibold))
                }
                .disabled(arrivals.isBusy)
                .accessibilityLabel(Text("도착 정보 새로고침"))
            }
            switch arrivals {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.l)
            case .message(let message):
                Text(message)
                    .font(.system(size: SettingsTokens.FontSize.callout))
                    .foregroundStyle(DesignTokens.Palette.textSecondary)
                    .padding(.vertical, DesignTokens.Spacing.s)
            case .rows(let rows, _, let isRefreshing):
                VStack(spacing: 0) {
                    ForEach(rows) { row in
                        arrivalRow(row)
                        if row.id != rows.last?.id {
                            Divider().overlay(DesignTokens.Palette.separatorGrouped)
                        }
                    }
                }
                .background(DesignTokens.Palette.surfaceGrouped, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous))
                .opacity(isRefreshing ? DesignTokens.Opacity.secondaryText : 1)
            }
        }
        .accessibilityIdentifier(AppConstants.AccessibilityID.nearbyArrivals)
    }

    private func arrivalRow(_ row: NearbyDisplayModel.ArrivalRow) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxxs) {
                    Text(row.title)
                        .font(.system(size: Tokens.FontSize.arrivalTitle, weight: .semibold))
                    if !row.subtitle.isEmpty {
                        Text(row.subtitle)
                            .font(.system(size: Tokens.FontSize.arrivalDetail))
                            .foregroundStyle(DesignTokens.Palette.textSecondary)
                    }
                }
                .lineLimit(1)
                Spacer()
                VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xxxs) {
                    Text(row.etaText)
                        .font(.system(size: Tokens.FontSize.arrivalEta, weight: .bold))
                        .monospacedDigit()
                    if !row.nextText.isEmpty {
                        Text(row.nextText)
                            .font(.system(size: Tokens.FontSize.arrivalDetail))
                            .foregroundStyle(DesignTokens.Palette.textSecondary)
                    }
                }
            }
            if let departureText = row.departureText {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Circle()
                        .fill(urgencyColor(row.urgency))
                        .frame(width: Tokens.urgencyDotSize, height: Tokens.urgencyDotSize)
                        .accessibilityHidden(true)
                    Text(departureText)
                        .font(.system(size: Tokens.FontSize.arrivalDetail, weight: .semibold))
                }
            }
        }
        .padding(Tokens.arrivalRowPadding)
        .accessibilityElement(children: .combine)
    }

    private func favoriteButton(_ selection: NearbyDisplayModel.Selection) -> some View {
        Button {
            Task { await viewModel.addSelectedToFavorites() }
        } label: {
            HStack(spacing: DesignTokens.Spacing.xs) {
                if selection.isSaving { ProgressView().tint(DesignTokens.Palette.textOnAccent) }
                Text(selection.actionTitle)
            }
            .font(.system(size: SettingsTokens.FontSize.callout, weight: .bold))
            .foregroundStyle(DesignTokens.Palette.textOnAccent)
            .frame(maxWidth: .infinity)
            .frame(height: SettingsTokens.primaryButtonHeight)
            .background(DesignTokens.Palette.accent, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(selection.isSaving || selection.isCalculatingWalk)
    }

    private func urgencyColor(_ urgency: DepartureUrgency?) -> Color {
        switch urgency {
        case .relaxed: DesignTokens.Hero.relaxed
        case .soon: DesignTokens.Hero.soon
        case .now: DesignTokens.Hero.now
        case .missed: DesignTokens.Palette.textTertiary
        case nil: DesignTokens.Palette.textTertiary
        }
    }
}

private extension NearbyDisplayModel.Arrivals {
    /// 불러오는 중이면 새로고침 버튼을 막는다
    var isBusy: Bool {
        switch self {
        case .loading: true
        case .rows(_, _, let isRefreshing): isRefreshing
        case .message: false
        }
    }
}
