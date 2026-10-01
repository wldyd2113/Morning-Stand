import SwiftUI

/// 스탠드 아래 패널: 출발 카운트다운 카드(왼쪽), 다른 노선·갱신 시각(오른쪽).
struct StandBottomPanelView: View {
    let viewModel: StandViewModel
    let display: StandDisplayModel

    @Environment(\.standPalette) private var palette
    @Environment(\.standScale) private var scale

    private typealias Tokens = DesignTokens.Stand

    var body: some View {
        HStack(alignment: .top, spacing: Tokens.bottomColumnSpacing * scale) {
            DepartureHeroView(hero: display.hero)
                .frame(width: Tokens.heroWidth * scale)
                .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 0) {
                Text("다른 노선")
                    .font(.system(size: Tokens.FontSize.sectionTitle * scale, weight: .semibold))
                    .foregroundStyle(palette.secondary)
                    .padding(Tokens.Padding.sectionTitle.scaled(scale))
                OtherRoutesView(otherRoutes: display.otherRoutes)
                Spacer(minLength: 0)
                StandFooterView(viewModel: viewModel, footer: display.footer)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(Tokens.bottomPanelPadding.scaled(scale))
    }
}
