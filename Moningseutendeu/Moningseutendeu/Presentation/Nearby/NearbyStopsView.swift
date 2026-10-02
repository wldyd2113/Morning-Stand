import SwiftUI

/// 주변 탭 첫 화면: 주변 정류장 찾기, 집 위치, 출근 자동 처리.
/// 정류장을 찾으면 지도 화면(`NearbyMapView`)으로 이동한다.
struct NearbyStopsView: View {
    @Bindable var viewModel: NearbyStopsViewModel

    @Environment(\.openURL) private var openURL

    private typealias Tokens = DesignTokens.Nearby
    private typealias SettingsTokens = DesignTokens.Settings

    var body: some View {
        let display = viewModel.display
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.l) {
                    searchCard(display)
                    homeCard(display.home)
                    automationCard(display.automation)
                }
                .frame(maxWidth: Tokens.contentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(SettingsTokens.screenPadding)
            }
            .background(DesignTokens.Palette.background.ignoresSafeArea())
            .foregroundStyle(DesignTokens.Palette.textPrimary)
            .navigationTitle("주변")
            .navigationDestination(isPresented: $viewModel.isMapPresented) {
                NearbyMapView(viewModel: viewModel)
            }
        }
        .tint(DesignTokens.Palette.accent)
        .accessibilityIdentifier(AppConstants.AccessibilityID.nearbyRoot)
    }

    // MARK: - 주변 정류장 찾기

    private func searchCard(_ display: NearbyDisplayModel) -> some View {
        VStack(spacing: DesignTokens.Spacing.m) {
            Image(systemName: DesignTokens.Symbol.nearbyTab)
                .font(.system(size: Tokens.FontSize.searchSymbol, weight: .semibold))
                .foregroundStyle(DesignTokens.Palette.textOnAccent)
                .frame(width: Tokens.searchIconSize, height: Tokens.searchIconSize)
                .background(DesignTokens.Palette.accent, in: Circle())
                .accessibilityHidden(true)
            Text("주변 정류장 찾기")
                .font(.system(size: Tokens.FontSize.searchTitle, weight: .bold))
            Text("현재 위치에서 반경 \(PolicyConstants.Location.nearbyRadiusMeters)m 안의 버스 정류장을 지도에 표시해요. 정류장을 누르면 버스가 얼마나 남았는지 볼 수 있어요")
                .font(.system(size: SettingsTokens.FontSize.footnote))
                .foregroundStyle(DesignTokens.Palette.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await viewModel.findNearby() }
            } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    if display.isLocating {
                        ProgressView().tint(DesignTokens.Palette.textOnAccent)
                    } else {
                        Image(systemName: DesignTokens.Symbol.location)
                    }
                    Text(display.isLocating ? "위치를 찾는 중" : "현재 위치에서 찾기")
                }
                .font(.system(size: SettingsTokens.FontSize.body, weight: .bold))
                .foregroundStyle(DesignTokens.Palette.textOnAccent)
                .frame(maxWidth: .infinity)
                .frame(height: SettingsTokens.primaryButtonHeight)
                .background(DesignTokens.Palette.accent, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(display.isLocating)
            .accessibilityIdentifier(AppConstants.AccessibilityID.nearbyFindButton)

            if let message = display.message {
                Text(message)
                    .font(.system(size: SettingsTokens.FontSize.footnote, weight: .semibold))
                    .foregroundStyle(DesignTokens.Palette.error)
                    .multilineTextAlignment(.center)
                if display.showsOpenSettings, let url = URL(string: AppConstants.SystemURL.appSettings) {
                    Button("설정 열기") { openURL(url) }
                        .font(.system(size: SettingsTokens.FontSize.callout, weight: .semibold))
                }
            }

            // 지도에서 뒤로 나왔을 때 다시 검색하지 않고 지난 결과를 볼 수 있게 한다
            if let summary = display.resultSummary, !display.isLocating {
                Button {
                    viewModel.isMapPresented = true
                } label: {
                    HStack {
                        Text(summary)
                        Text(display.locationText ?? "")
                            .foregroundStyle(DesignTokens.Palette.textTertiary)
                        Spacer()
                        Text("지도 보기")
                        Image(systemName: DesignTokens.Symbol.chevronRight)
                    }
                    .font(.system(size: SettingsTokens.FontSize.footnote, weight: .semibold))
                }
                .padding(.top, DesignTokens.Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Tokens.searchCardPadding)
        .background(DesignTokens.Palette.surfaceGrouped, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.large, style: .continuous))
    }

    // MARK: - 집 · 자동 처리

    private func homeCard(_ home: NearbyDisplayModel.Home) -> some View {
        card {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.m) {
                cardIcon(DesignTokens.Symbol.home, isActive: home.isSet)
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
                    Text(home.title)
                        .font(.system(size: SettingsTokens.FontSize.footnote))
                        .foregroundStyle(DesignTokens.Palette.textSecondary)
                    Button {
                        Task { await viewModel.setCurrentLocationAsHome() }
                    } label: {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            if home.isUpdating { ProgressView() }
                            Text(home.actionTitle)
                        }
                        .font(.system(size: SettingsTokens.FontSize.callout, weight: .semibold))
                    }
                    .disabled(home.isUpdating)
                    .accessibilityIdentifier(AppConstants.AccessibilityID.nearbySetHomeButton)
                }
            }
        }
    }

    private func automationCard(_ automation: NearbyDisplayModel.Automation) -> some View {
        card {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.m) {
                cardIcon(DesignTokens.Symbol.door, isActive: automation.isOn)
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Toggle(isOn: Binding(get: { automation.isOn }, set: { isOn in Task { await viewModel.setAutomation(isOn) } })) {
                        Text("집을 나서면 자동 처리")
                            .font(.system(size: SettingsTokens.FontSize.callout, weight: .semibold))
                    }
                    .disabled(automation.isUpdating || !automation.isAvailable)
                    .accessibilityIdentifier(AppConstants.AccessibilityID.nearbyAutomationToggle)
                    Text(automation.detail)
                        .font(.system(size: SettingsTokens.FontSize.footnote))
                        .foregroundStyle(DesignTokens.Palette.textSecondary)
                    if let reason = automation.unavailableReason {
                        Label(reason, systemImage: DesignTokens.Symbol.home)
                            .font(.system(size: SettingsTokens.FontSize.footnote, weight: .semibold))
                            .foregroundStyle(DesignTokens.Palette.accent)
                    }
                    if let error = automation.errorMessage {
                        Text(error)
                            .font(.system(size: SettingsTokens.FontSize.footnote, weight: .semibold))
                            .foregroundStyle(DesignTokens.Palette.error)
                    }
                }
            }
        }
    }

    private func card(@ViewBuilder content: () -> some View) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.cardPadding)
            .background(DesignTokens.Palette.surfaceGrouped, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous))
    }

    private func cardIcon(_ symbol: String, isActive: Bool) -> some View {
        Image(systemName: symbol)
            .font(.system(size: SettingsTokens.FontSize.callout, weight: .semibold))
            .foregroundStyle(isActive ? DesignTokens.Palette.textOnAccent : DesignTokens.Palette.textSecondary)
            .frame(width: Tokens.iconSize, height: Tokens.iconSize)
            .background(isActive ? DesignTokens.Palette.accent : DesignTokens.Palette.surfaceElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.m, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview {
    NearbyStopsView(viewModel: AppDependencies.preview().makeNearbyStopsViewModel())
        .preferredColorScheme(.dark)
}
