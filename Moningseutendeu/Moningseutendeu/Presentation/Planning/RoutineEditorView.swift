import SwiftUI

/// 요일별 루틴: 요일 칩 + 선택한 요일의 설정.
struct RoutineEditorView: View {
    let weekdays: [PlanningDisplayModel.DayChip]
    let summary: String
    let routine: PlanningDisplayModel.Routine?
    let onSelectDay: (Weekday) -> Void
    let onToggle: () -> Void

    private typealias Tokens = DesignTokens.Planning

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.ml) {
            HStack(alignment: .firstTextBaseline) {
                Text("요일별 루틴")
                    .font(.system(size: Tokens.FontSize.sectionTitle, weight: .bold))
                Spacer()
                Text(summary)
                    .font(.system(size: Tokens.FontSize.routeSchedule))
                    .foregroundStyle(DesignTokens.Palette.textSecondary)
            }

            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(weekdays) { day in
                    dayChip(day)
                }
            }

            if let routine {
                routineCard(routine)
            }
        }
    }

    private func dayChip(_ day: PlanningDisplayModel.DayChip) -> some View {
        let foreground: Color = day.isSelected
            ? DesignTokens.Palette.textOnAccent
            : (day.isEnabled ? DesignTokens.Palette.textPrimary : DesignTokens.Palette.textDisabled)
        let dot: Color = day.isEnabled
            ? (day.isSelected ? DesignTokens.Palette.textOnAccent : DesignTokens.Palette.accent)
            : .clear

        return Button { onSelectDay(day.weekday) } label: {
            VStack(spacing: DesignTokens.Spacing.xxxs) {
                Text(day.label)
                    .font(.system(size: Tokens.FontSize.dayChip, weight: .bold))
                Circle()
                    .fill(dot)
                    .frame(width: Tokens.dayDotSize, height: Tokens.dayDotSize)
            }
            .foregroundStyle(foreground)
            .frame(width: Tokens.dayChipSize, height: Tokens.dayChipSize)
            .background(day.isSelected ? DesignTokens.Palette.accent : DesignTokens.Palette.surfaceGrouped, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(day.label))
        .accessibilityValue(day.isEnabled ? Text("루틴 켜짐") : Text("루틴 꺼짐"))
        .accessibilityAddTraits(day.isSelected ? .isSelected : [])
        .animation(DesignTokens.Animation.selection, value: day)
    }

    private func routineCard(_ routine: PlanningDisplayModel.Routine) -> some View {
        VStack(spacing: 0) {
            settingRow {
                Toggle(routine.toggleTitle, isOn: Binding(get: { routine.isEnabled }, set: { _ in onToggle() }))
                    .tint(DesignTokens.Palette.accent)
            }
            separator
            Group {
                settingRow {
                    Text("출근 시각")
                    Spacer()
                    Text(routine.timeText)
                        .monospacedDigit()
                        .padding(Tokens.valueChipPadding)
                        .background(DesignTokens.Palette.surfaceElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.valueChip))
                }
                separator
                settingRow {
                    Text("기본 경로")
                    Spacer()
                    valueText(routine.routeText)
                }
                separator
                settingRow {
                    Text("알림 시점")
                    Spacer()
                    valueText(routine.alertText)
                }
            }
            .opacity(routine.isEnabled ? 1 : DesignTokens.Opacity.disabled)
        }
        .font(.system(size: Tokens.FontSize.row))
        .background(DesignTokens.Palette.surfaceCard, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous))
    }

    private func settingRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack { content() }
            .frame(minHeight: Tokens.settingRowHeight)
            .padding(.horizontal, DesignTokens.Spacing.lx)
    }

    private var separator: some View {
        Rectangle()
            .fill(DesignTokens.Palette.separatorCard)
            .frame(height: 1)
    }

    private func valueText(_ text: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Text(text)
            Image(systemName: DesignTokens.Symbol.chevronRight)
                .font(.system(size: Tokens.FontSize.caption, weight: .semibold))
        }
        .foregroundStyle(DesignTokens.Palette.textSecondary)
        .lineLimit(1)
    }
}
