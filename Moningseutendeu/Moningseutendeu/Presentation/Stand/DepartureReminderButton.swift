import SwiftUI

/// 조작판 아래 큰 버튼: 출발 N분 전 알림 예약 / 취소.
struct DepartureReminderButton: View {
    let reminder: StandControlsDisplayModel.Reminder
    let action: () -> Void

    @Environment(\.standPalette) private var palette
    @Environment(\.standScale) private var scale

    private typealias Tokens = DesignTokens.Stand.Controls

    var body: some View {
        Button(action: action) {
            HStack(spacing: Tokens.reminderSpacing * scale) {
                Image(systemName: isScheduled ? DesignTokens.Symbol.reminderOn : DesignTokens.Symbol.reminderOff)
                    .font(.system(size: Tokens.reminderFont * scale, weight: .semibold))
                Text(title)
                    .font(.system(size: Tokens.reminderFont * scale, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                if case .scheduled(_, let detail) = reminder {
                    Text(detail)
                        .font(.system(size: Tokens.reminderDetailFont * scale, weight: .medium))
                        .opacity(DesignTokens.Opacity.secondaryText)
                }
            }
            .foregroundStyle(isScheduled ? DesignTokens.Palette.textOnAccent : palette.text)
            .padding(.horizontal, DesignTokens.Spacing.xl * scale)
            .frame(maxWidth: .infinity, minHeight: Tokens.reminderHeight * scale)
            .background(isScheduled ? palette.accent : palette.cardStrong, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(reminder == .unavailable)
        .opacity(reminder == .unavailable ? DesignTokens.Opacity.disabled : 1)
        .accessibilityIdentifier(AppConstants.AccessibilityID.standReminder)
    }

    private var isScheduled: Bool {
        if case .scheduled = reminder { return true }
        return false
    }

    private var title: String {
        switch reminder {
        case .unavailable: String(localized: "출발 알림을 걸 수 없어요")
        case .available(let title), .scheduled(let title, _): title
        }
    }
}
