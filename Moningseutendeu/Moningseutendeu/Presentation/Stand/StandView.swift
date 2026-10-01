import SwiftUI

/// 반접힘 스탠드 화면. 위 패널: 시계·날씨 / 아래 패널: 출발 카운트다운·다른 노선.
///
/// 시안(960×876pt) 비율을 유지하면서 화면 크기에 맞춰 배율을 정하고, 하위 View는 시안 값에 배율을 곱한다.
struct StandView: View {
    let viewModel: StandViewModel

    var body: some View {
        let display = viewModel.display
        let palette = StandPalette.resolve(display.theme)

        GeometryReader { proxy in
            let scale = Self.scale(for: proxy.size)
            VStack(spacing: 0) {
                StandTopPanelView(viewModel: viewModel, display: display)
                    .frame(maxHeight: .infinity)
                hinge(scale: scale)
                StandBottomPanelView(viewModel: viewModel, display: display)
                    .frame(maxHeight: .infinity)
            }
            .environment(\.standScale, scale)
        }
        .environment(\.standPalette, palette)
        .background(palette.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .accessibilityIdentifier(AppConstants.AccessibilityID.standRoot)
        .task { await viewModel.start() }
    }

    /// 힌지 부분. 중요한 숫자가 접히는 곳에 걸치지 않게 비워 두고 얇은 선만 긋는다.
    private func hinge(scale: CGFloat) -> some View {
        Rectangle()
            .fill(DesignTokens.Stand.hingeLine)
            .frame(height: DesignTokens.Stand.hingeLineHeight)
            .frame(height: DesignTokens.Stand.hingeGap * scale)
            .accessibilityHidden(true)
    }

    static func scale(for size: CGSize) -> CGFloat {
        let reference = DesignTokens.Stand.referenceSize
        return min(size.width / reference.width, size.height / reference.height)
    }
}

#Preview("곧 출발", traits: .landscapeLeft) {
    StandView(viewModel: AppDependencies.preview(scenario: .soon).makeStandViewModel())
}

#Preview("여유", traits: .landscapeLeft) {
    StandView(viewModel: AppDependencies.preview(scenario: .relaxed).makeStandViewModel())
}

#Preview("지금 출발", traits: .landscapeLeft) {
    StandView(viewModel: AppDependencies.preview(scenario: .now).makeStandViewModel())
}

#Preview("놓침", traits: .landscapeLeft) {
    StandView(viewModel: AppDependencies.preview(scenario: .missed).makeStandViewModel())
}

#Preview("야간", traits: .landscapeLeft) {
    StandView(viewModel: AppDependencies.preview(scenario: .relaxed, theme: .night).makeStandViewModel())
}

#Preview("로딩", traits: .landscapeLeft) {
    StandView(viewModel: AppDependencies.preview(scenario: .loading).makeStandViewModel())
}

#Preview("날씨만 지연", traits: .landscapeLeft) {
    StandView(viewModel: AppDependencies.preview(scenario: .weatherStale).makeStandViewModel())
}

#Preview("오프라인", traits: .landscapeLeft) {
    StandView(viewModel: AppDependencies.preview(scenario: .offline).makeStandViewModel())
}

#Preview("운행 종료", traits: .landscapeLeft) {
    StandView(viewModel: AppDependencies.preview(scenario: .ended).makeStandViewModel())
}
