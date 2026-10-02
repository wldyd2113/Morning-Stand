import SwiftUI

/// 펼침 화면을 탭으로 나눈다: 경로 · 주변 · 기록.
struct PlanningTabView<ModeToggle: View>: View {
    @Binding var selection: PlanningTab
    let planningViewModel: PlanningViewModel
    let nearbyViewModel: NearbyStopsViewModel
    let historyViewModel: CommuteHistoryViewModel
    let onOpenSettings: () -> Void
    /// 탭 막대와 겹치지 않게 각 탭 내용 위에 올리는 스탠드 전환 버튼
    @ViewBuilder let modeToggle: () -> ModeToggle

    var body: some View {
        TabView(selection: $selection) {
            Tab("경로", systemImage: DesignTokens.Symbol.routeTab, value: PlanningTab.routes) {
                PlanningView(viewModel: planningViewModel, onOpenSettings: onOpenSettings)
                    .overlay(alignment: .bottomTrailing, content: modeToggle)
            }
            Tab("주변", systemImage: DesignTokens.Symbol.nearbyTab, value: PlanningTab.nearby) {
                NearbyStopsView(viewModel: nearbyViewModel)
                    .overlay(alignment: .bottomTrailing, content: modeToggle)
            }
            Tab("기록", systemImage: DesignTokens.Symbol.historyTab, value: PlanningTab.history) {
                CommuteHistoryView(viewModel: historyViewModel)
                    .overlay(alignment: .bottomTrailing, content: modeToggle)
            }
        }
        .tint(DesignTokens.Palette.accent)
        .preferredColorScheme(.dark)
        .accessibilityIdentifier(AppConstants.AccessibilityID.planningTabs)
    }
}

#Preview {
    @Previewable @State var selection = PlanningTab.history
    let dependencies = AppDependencies.preview()
    PlanningTabView(
        selection: $selection,
        planningViewModel: dependencies.makePlanningViewModel(),
        nearbyViewModel: dependencies.makeNearbyStopsViewModel(),
        historyViewModel: dependencies.makeCommuteHistoryViewModel(),
        onOpenSettings: {}
    ) { EmptyView() }
}
