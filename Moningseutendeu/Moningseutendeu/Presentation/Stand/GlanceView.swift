import SwiftUI

/// 접힘(커버 화면) 한눈 모드. 스탠드 화면과 같은 값(StandViewModel)을 좁은 세로 화면에 맞춰 보여준다.
/// 위: 시계·날씨 / 가운데: 출발 카운트다운 / 아래: 다른 노선·갱신 시각
struct GlanceView: View {
    let viewModel: StandViewModel

    private typealias Tokens = DesignTokens.Glance

    var body: some View {
        let display = viewModel.display
        let palette = StandPalette.resolve(display.theme)

        VStack(alignment: .leading, spacing: Tokens.sectionSpacing) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    StandClockView(viewModel: viewModel)
                        .environment(\.standScale, Tokens.clockScale)
                    Text(display.dateText)
                        .font(.system(size: Tokens.dateFontSize, weight: .semibold))
                        .foregroundStyle(palette.secondary)
                }
                Spacer(minLength: DesignTokens.Spacing.s)
                StandWeatherView(panel: display.weather)
                    .environment(\.standScale, Tokens.weatherScale)
            }

            StandBannerView(banner: display.banner)
                .environment(\.standScale, Tokens.bannerScale)

            DepartureHeroView(hero: display.hero)
                .environment(\.standScale, Tokens.heroScale)
                .frame(height: Tokens.heroHeight)

            OtherRoutesView(otherRoutes: display.otherRoutes, maxRows: Tokens.maxOtherRoutes)
                .environment(\.standScale, Tokens.listScale)

            Spacer(minLength: 0)

            StandFooterView(viewModel: viewModel, footer: display.footer)
                .environment(\.standScale, Tokens.listScale)
        }
        .padding(Tokens.padding)
        .environment(\.standPalette, palette)
        .background(palette.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .accessibilityIdentifier(AppConstants.AccessibilityID.glanceRoot)
        .task { await viewModel.start() }
    }
}

#Preview("곧 출발") {
    GlanceView(viewModel: AppDependencies.preview(scenario: .soon).makeStandViewModel())
}

#Preview("놓침") {
    GlanceView(viewModel: AppDependencies.preview(scenario: .missed).makeStandViewModel())
}

#Preview("야간") {
    GlanceView(viewModel: AppDependencies.preview(scenario: .relaxed, theme: .night).makeStandViewModel())
}
