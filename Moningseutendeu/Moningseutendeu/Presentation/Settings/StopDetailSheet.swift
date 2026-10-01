import SwiftUI

/// 정류장 검색 화면 아래 시트: 도보 시간 스테퍼, 알림 받을 노선, 즐겨찾기 추가 버튼.
struct StopDetailSheet: View {
    let selection: StopSearchDisplayModel.Selection
    let viewModel: StopSearchViewModel

    @State private var dragOffset: CGFloat = 0

    private typealias Tokens = DesignTokens.Settings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: viewModel.clearSelection) {
                Capsule()
                    .fill(DesignTokens.Palette.sheetHandle)
                    .frame(width: Tokens.sheetHandle.width, height: Tokens.sheetHandle.height)
                    .frame(maxWidth: .infinity, minHeight: Tokens.sheetHandle.height * 2)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("닫기"))

            Text(selection.name)
                .font(.system(size: Tokens.FontSize.sheetTitle, weight: .bold))
                .padding(.top, DesignTokens.Spacing.ml)
            Text(selection.detail)
                .font(.system(size: Tokens.FontSize.subheadline))
                .foregroundStyle(DesignTokens.Palette.textSecondary)
                .padding(.top, DesignTokens.Spacing.xxxs)

            sectionTitle("정류장까지 도보 시간")
                .padding(.top, DesignTokens.Spacing.lx)
            walkStepper
                .padding(.top, DesignTokens.Spacing.s)
            Text(selection.walkHint)
                .font(.system(size: Tokens.FontSize.footnote))
                .foregroundStyle(DesignTokens.Palette.textTertiary)
                .padding(.top, DesignTokens.Spacing.xs)

            sectionTitle("알림 받을 노선")
                .padding(.top, DesignTokens.Spacing.l)
            routeChips
                .padding(.top, DesignTokens.Spacing.s)

            Button(action: viewModel.addSelectedToFavorites) {
                Label(selection.actionTitle, systemImage: selection.isFavorite ? DesignTokens.Symbol.checkmark : DesignTokens.Symbol.starFilled)
                    .font(.system(size: Tokens.FontSize.body, weight: .bold))
                    .foregroundStyle(DesignTokens.Palette.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: Tokens.primaryButtonHeight)
                    .background(DesignTokens.Palette.accent, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, DesignTokens.Spacing.lx)
            .accessibilityIdentifier(AppConstants.AccessibilityID.addFavoriteButton)
        }
        .padding(Tokens.sheetPadding)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: DesignTokens.Radius.sheet, topTrailingRadius: DesignTokens.Radius.sheet, style: .continuous)
                .fill(DesignTokens.Palette.surfaceGrouped)
                .shadow(color: DesignTokens.Palette.sheetShadow, radius: Tokens.sheetShadowRadius, y: Tokens.sheetShadowY)
                .ignoresSafeArea(edges: .bottom)
        )
        .offset(y: dragOffset)
        .gesture(dismissDrag)
    }

    /// 아래로 끌면 따라 내려가고, 충분히 끌었으면 닫는다.
    private var dismissDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = max(value.translation.height, 0)
            }
            .onEnded { value in
                if value.translation.height > Tokens.sheetDismissDragDistance {
                    viewModel.clearSelection()
                }
                withAnimation(DesignTokens.Animation.sheet) { dragOffset = 0 }
            }
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.system(size: Tokens.FontSize.callout))
            .foregroundStyle(DesignTokens.Palette.textSecondary)
    }

    private var walkStepper: some View {
        HStack {
            stepperButton(symbol: DesignTokens.Symbol.minus, label: "도보 시간 줄이기", isEnabled: selection.canDecreaseWalk, action: viewModel.decreaseWalk)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.xxxs) {
                Text(selection.walkMinutesText)
                    .font(.system(size: Tokens.FontSize.stepperValue, weight: .bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("분")
                    .font(.system(size: Tokens.FontSize.stepperUnit, weight: .semibold))
                    .foregroundStyle(DesignTokens.Palette.textSecondary)
            }
            .animation(DesignTokens.Animation.numberTransition, value: selection.walkMinutesText)
            .accessibilityElement(children: .combine)
            Spacer()
            stepperButton(symbol: DesignTokens.Symbol.plus, label: "도보 시간 늘리기", isEnabled: selection.canIncreaseWalk, action: viewModel.increaseWalk)
        }
        .padding(Tokens.stepperPadding)
        .background(DesignTokens.Palette.surfaceElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous))
    }

    private func stepperButton(symbol: String, label: LocalizedStringKey, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: Tokens.FontSize.stepperSymbol, weight: .medium))
                .foregroundStyle(DesignTokens.Palette.textPrimary)
                .frame(width: Tokens.stepperButtonSize, height: Tokens.stepperButtonSize)
                .background(DesignTokens.Palette.surfaceControl, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : DesignTokens.Opacity.disabled)
        .accessibilityLabel(Text(label))
    }

    @ViewBuilder
    private var routeChips: some View {
        if let message = selection.routesMessage {
            Text(message)
                .font(.system(size: Tokens.FontSize.footnote))
                .foregroundStyle(DesignTokens.Palette.textTertiary)
        }
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.s) {
            ForEach(selection.routes) { route in
                Button { viewModel.toggleRoute(route.name) } label: {
                    Text(route.name)
                        .font(.system(size: Tokens.FontSize.callout, weight: .bold))
                        .foregroundStyle(route.isTracked ? DesignTokens.Palette.accent : DesignTokens.Palette.textInactive)
                        .padding(Tokens.routeChipPadding)
                        .background(route.isTracked ? DesignTokens.Palette.accentSoftBackground : DesignTokens.Palette.surfaceElevated, in: Capsule())
                        .overlay(Capsule().strokeBorder(route.isTracked ? DesignTokens.Palette.accent : .clear, lineWidth: Tokens.routeChipRingWidth))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(route.isTracked ? .isSelected : [])
            }
            }
        }
    }
}
