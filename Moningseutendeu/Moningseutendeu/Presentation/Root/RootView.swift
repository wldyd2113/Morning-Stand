import SwiftUI

/// 앱 루트. 자세에 따라 스탠드/플래닝(탭: 경로·주변·기록) 화면을 바꾸고, 설정은 시트로 연다.
struct RootView: View {
    @State private var rootViewModel: RootViewModel
    @State private var standViewModel: StandViewModel
    @State private var planningViewModel: PlanningViewModel
    @State private var nearbyViewModel: NearbyStopsViewModel
    @State private var historyViewModel: CommuteHistoryViewModel
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _rootViewModel = State(initialValue: dependencies.makeRootViewModel())
        _standViewModel = State(initialValue: dependencies.makeStandViewModel())
        _planningViewModel = State(initialValue: dependencies.makePlanningViewModel())
        _nearbyViewModel = State(initialValue: dependencies.makeNearbyStopsViewModel())
        _historyViewModel = State(initialValue: dependencies.makeCommuteHistoryViewModel())
    }

    var body: some View {
        @Bindable var rootViewModel = rootViewModel
        GeometryReader { proxy in
            content
                .onChange(of: proxy.size, initial: true) { _, size in
                    rootViewModel.updateContainerSize(size)
                }
        }
        .ignoresSafeArea(.keyboard)
        .task { await rootViewModel.observeMotion() }
        .task(id: rootViewModel.candidatePosture) { await rootViewModel.settlePosture() }
        .sheet(isPresented: $rootViewModel.isSettingsPresented) {
            SettingsView(
                stopSearchViewModel: dependencies.makeStopSearchViewModel(),
                airQualityStationViewModel: dependencies.makeAirQualityStationViewModel(),
                notificationViewModel: dependencies.makeNotificationSettingsViewModel()
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        switch rootViewModel.screenMode {
        case .stand:
            StandView(viewModel: standViewModel)
                .overlay(alignment: .trailing) { modeToggle(symbol: DesignTokens.Symbol.switchToPlanning) }
        case .planning:
            @Bindable var rootViewModel = rootViewModel
            PlanningTabView(
                selection: $rootViewModel.planningTab,
                planningViewModel: planningViewModel,
                nearbyViewModel: nearbyViewModel,
                historyViewModel: historyViewModel,
                onOpenSettings: rootViewModel.openSettings
            ) {
                modeToggle(symbol: DesignTokens.Symbol.switchToStand)
            }
        }
    }

    /// 자세 추정이 틀렸을 때 쓰는 수동 전환 버튼. 스탠드 화면에서는 비어 있는 힌지 줄 끝에 흐리게 둔다.
    private func modeToggle(symbol: String) -> some View {
        Button(action: rootViewModel.toggleMode) {
            Image(systemName: symbol)
                .font(.system(size: DesignTokens.Settings.FontSize.body, weight: .semibold))
                .foregroundStyle(DesignTokens.Palette.textSecondary)
                .frame(width: DesignTokens.Stand.Size.modeToggle, height: DesignTokens.Stand.Size.modeToggle)
                .contentShape(Rectangle())
        }
        .opacity(DesignTokens.Opacity.modeToggle)
        .padding(DesignTokens.Spacing.s)
        .accessibilityLabel(rootViewModel.screenMode == .stand ? Text("플래닝 화면으로 전환") : Text("스탠드 화면으로 전환"))
        .accessibilityIdentifier(AppConstants.AccessibilityID.modeToggle)
    }
}

#Preview("반접힘", traits: .landscapeLeft) {
    RootView(dependencies: .preview(posture: .halfOpened))
}

#Preview("펼침") {
    RootView(dependencies: .preview(posture: .flat))
}
