import SwiftUI

/// 스탠드 위 패널: 시계·날짜(왼쪽), 날씨·미세먼지(오른쪽), 배너(아래줄).
struct StandTopPanelView: View {
    let viewModel: StandViewModel
    let display: StandDisplayModel

    @Environment(\.standPalette) private var palette
    @Environment(\.standScale) private var scale

    private typealias Tokens = DesignTokens.Stand

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.topRowSpacing * scale) {
            HStack(alignment: .top, spacing: Tokens.topColumnSpacing * scale) {
                VStack(alignment: .leading, spacing: 0) {
                    StandClockView(viewModel: viewModel)
                    Text(display.dateText)
                        .font(.system(size: Tokens.FontSize.date * scale, weight: .semibold))
                        .foregroundStyle(palette.secondary)
                        .padding(.top, Tokens.Spacing.dateTop * scale)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                StandWeatherView(panel: display.weather)
                    .frame(width: Tokens.weatherColumnWidth * scale, alignment: .trailing)
            }
            .frame(maxHeight: .infinity, alignment: .top)

            StandBannerView(banner: display.banner)
        }
        .padding(Tokens.topPanelPadding.scaled(scale))
    }
}
