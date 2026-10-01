import SwiftUI

/// 왼쪽 경로 목록.
struct PlanningSidebarView: View {
    let routes: [PlanningDisplayModel.RouteRow]
    let onSelect: (String) -> Void
    let onAddRoute: () -> Void
    let onOpenSettings: () -> Void

    private typealias Tokens = DesignTokens.Planning

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text("경로")
                    .font(.system(size: Tokens.FontSize.title, weight: .bold))
                    .tracking(Tokens.Tracking.title)
                Spacer()
                SettingsButton(action: onOpenSettings)
            }
            .padding(.horizontal, DesignTokens.Spacing.s)
            .padding(.bottom, DesignTokens.Spacing.m)

            ForEach(routes) { route in
                RouteRowView(route: route) { onSelect(route.id) }
            }

            Button(action: onAddRoute) {
                Label("경로 추가", systemImage: DesignTokens.Symbol.plus)
                    .font(.system(size: Tokens.FontSize.subtitle, weight: .medium))
                    .foregroundStyle(DesignTokens.Palette.accent)
                    .padding(Tokens.routeRowPadding)
            }
            Spacer(minLength: 0)
        }
        .padding(Tokens.sidebarPadding)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(DesignTokens.Palette.surfaceSidebar.ignoresSafeArea())
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(DesignTokens.Palette.separatorSidebar)
                .frame(width: 1)
                .ignoresSafeArea()
        }
    }
}

/// 경로 한 줄 (이름, 일정, 최단 시간). 사이드바와 좁은 화면의 가로 목록에서 같이 쓴다.
struct RouteRowView: View {
    let route: PlanningDisplayModel.RouteRow
    let action: () -> Void

    private typealias Tokens = DesignTokens.Planning

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.m) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxxs) {
                    Text(route.name)
                        .font(.system(size: Tokens.FontSize.routeName, weight: .semibold))
                        .foregroundStyle(DesignTokens.Palette.textPrimary)
                    Text(route.schedule)
                        .font(.system(size: Tokens.FontSize.routeSchedule))
                        .foregroundStyle(DesignTokens.Palette.textSecondary)
                }
                .lineLimit(1)
                Spacer(minLength: 0)
                Text(route.bestText)
                    .font(.system(size: Tokens.FontSize.routeBest, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.Palette.textPrimary)
            }
            .padding(Tokens.routeRowPadding)
            .background(
                route.isSelected ? DesignTokens.Palette.surfaceElevated : .clear,
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(route.isSelected ? .isSelected : [])
        .animation(DesignTokens.Animation.selection, value: route.isSelected)
    }
}
