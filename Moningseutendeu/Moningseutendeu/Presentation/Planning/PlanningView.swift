import SwiftUI

/// 펼침 플래닝 화면. 넓으면 사이드바(경로 목록) + 상세 2단, 좁으면 1단으로 보여준다.
struct PlanningView: View {
    let viewModel: PlanningViewModel
    let onOpenSettings: () -> Void

    private typealias Tokens = DesignTokens.Planning

    var body: some View {
        let display = viewModel.display
        GeometryReader { proxy in
            if proxy.size.width >= Tokens.splitMinimumWidth {
                HStack(spacing: 0) {
                    PlanningSidebarView(routes: display.routes, onSelect: viewModel.selectRoute(id:), onAddRoute: viewModel.addRoute, onOpenSettings: onOpenSettings)
                        .frame(width: Tokens.sidebarWidth)
                    PlanningDetailView(viewModel: viewModel, display: display)
                        .padding(Tokens.detailPadding)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
                        compactHeader
                        compactRoutes(display.routes)
                        PlanningDetailView(viewModel: viewModel, display: display)
                    }
                    .padding(Tokens.compactDetailPadding)
                }
            }
        }
        .background(DesignTokens.Palette.background.ignoresSafeArea())
        .foregroundStyle(DesignTokens.Palette.textPrimary)
        .preferredColorScheme(.dark)
        .accessibilityIdentifier(AppConstants.AccessibilityID.planningRoot)
        .task(id: viewModel.reloadToken) { await viewModel.load() }
        .sheet(item: Binding(get: { viewModel.editor }, set: { if $0 == nil { viewModel.finishEditing() } })) { editor in
            RouteEditorView(viewModel: editor)
        }
    }

    private var compactHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("경로")
                .font(.system(size: Tokens.FontSize.title, weight: .bold))
                .tracking(Tokens.Tracking.title)
            Spacer()
            AddRouteButton(action: viewModel.addRoute)
            SettingsButton(action: onOpenSettings)
        }
    }

    private func compactRoutes(_ routes: [PlanningDisplayModel.RouteRow]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.s) {
                ForEach(routes) { route in
                    RouteRowView(route: route) { viewModel.selectRoute(id: route.id) }
                        .frame(width: Tokens.compactRouteCardWidth)
                }
            }
        }
    }
}

/// 경로 추가 버튼
struct AddRouteButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: DesignTokens.Symbol.plus)
                .font(.system(size: DesignTokens.Planning.FontSize.routeBest, weight: .medium))
                .foregroundStyle(DesignTokens.Palette.accent)
        }
        .accessibilityLabel(Text("경로 추가"))
        .accessibilityIdentifier(AppConstants.AccessibilityID.addRouteButton)
    }
}

/// 설정 화면을 여는 톱니 버튼
struct SettingsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: DesignTokens.Symbol.settings)
                .font(.system(size: Tokens.FontSize.routeBest, weight: .medium))
                .foregroundStyle(DesignTokens.Palette.accent)
        }
        .accessibilityLabel(Text("설정"))
        .accessibilityIdentifier(AppConstants.AccessibilityID.settingsButton)
    }

    private typealias Tokens = DesignTokens.Planning
}

#Preview("펼침 · 가로", traits: .landscapeLeft) {
    PlanningView(viewModel: AppDependencies.preview().makePlanningViewModel(), onOpenSettings: {})
}

#Preview("펼침 · 세로") {
    PlanningView(viewModel: AppDependencies.preview().makePlanningViewModel(), onOpenSettings: {})
}
