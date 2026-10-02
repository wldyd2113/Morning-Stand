import SwiftUI

/// 스탠드 아래 패널: 출발 카운트다운 카드(왼쪽), 다른 노선·갱신 시각(오른쪽).
struct StandBottomPanelView: View {
    let viewModel: StandViewModel
    let display: StandDisplayModel

    @Environment(\.standPalette) private var palette
    @Environment(\.standScale) private var scale

    private typealias Tokens = DesignTokens.Stand

    var body: some View {
        GeometryReader { proxy in
            let spacing = Tokens.bottomColumnSpacing * scale
            // 카드는 시안 폭까지 쓰되, 세로 반접힘처럼 좁으면 조작판 최소 폭을 남기고 줄어든다
            let heroWidth = max(min(Tokens.heroWidth * scale, proxy.size.width - Tokens.Controls.minColumnWidth * scale - spacing), 0)
            HStack(alignment: .top, spacing: spacing) {
                // 카운트다운 카드를 좌우로 밀면 즐겨찾기 정류장을 넘긴다
                DepartureHeroView(hero: display.hero)
                    .frame(width: heroWidth)
                    .frame(maxHeight: .infinity)
                    .gesture(stopSwipe)

                // 아래 반쪽은 손으로 조작하는 판: 정류장 넘기기, 노선 고정, 출발 알림
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.s * scale) {
                    StandStopPagerView(controls: controls, onPrevious: viewModel.showPreviousStop, onNext: viewModel.showNextStop)
                    OtherRoutesView(otherRoutes: display.otherRoutes, maxRows: Tokens.Controls.maxRows, onSelect: viewModel.pinRoute(id:))
                    Spacer(minLength: 0)
                    DepartureReminderButton(reminder: controls.reminder) {
                        Task { await viewModel.toggleDepartureReminder() }
                    }
                    StandFooterView(viewModel: viewModel, footer: display.footer)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .padding(Tokens.bottomPanelPadding.scaled(scale))
    }

    private var controls: StandControlsDisplayModel { viewModel.controls }

    private var stopSwipe: some Gesture {
        DragGesture(minimumDistance: Tokens.Controls.swipeThreshold * scale / 2)
            .onEnded { value in
                let threshold = Tokens.Controls.swipeThreshold * scale
                if value.translation.width <= -threshold {
                    viewModel.showNextStop()
                } else if value.translation.width >= threshold {
                    viewModel.showPreviousStop()
                }
            }
    }
}
