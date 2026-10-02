import SwiftUI

/// 협탁 기상 알람 설정 화면.
struct WakeAlarmSettingsView: View {
    @Bindable var viewModel: WakeAlarmSettingsViewModel

    var body: some View {
        Form {
            Section {
                Toggle("기상 알람", isOn: $viewModel.isEnabled)
                DatePicker("시각", selection: $viewModel.time, displayedComponents: .hourAndMinute)
                    .disabled(!viewModel.isEnabled)
                HStack(spacing: DesignTokens.Spacing.xs) {
                    ForEach(viewModel.dayChips) { chip in
                        Button { viewModel.toggleWeekday(chip.weekday) } label: {
                            Text(chip.label)
                                .font(.system(size: DesignTokens.Settings.FontSize.callout, weight: .bold))
                                .foregroundStyle(chip.isSelected ? DesignTokens.Palette.textOnAccent : DesignTokens.Palette.textSecondary)
                                .frame(maxWidth: .infinity, minHeight: DesignTokens.Settings.starButtonSize)
                                .background(chip.isSelected ? DesignTokens.Palette.accent : DesignTokens.Palette.surfaceElevated, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(chip.isSelected ? .isSelected : [])
                    }
                }
                .disabled(!viewModel.isEnabled)
                .opacity(viewModel.isEnabled ? 1 : DesignTokens.Opacity.disabled)
            } footer: {
                Text(viewModel.summary)
            }

            Section {
                Button {
                    Task { await viewModel.save() }
                } label: {
                    if viewModel.isSaving {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("저장").frame(maxWidth: .infinity)
                    }
                }
                .disabled(!viewModel.hasChanges || viewModel.isSaving)
            } footer: {
                if let message = viewModel.message {
                    Text(message).foregroundStyle(DesignTokens.Palette.accent)
                } else {
                    Text("무음 모드에서도 울려요. 알람 화면의 \"출발 보기\"를 누르면 오늘의 출발 카운트다운이 바로 열려요.")
                }
            }
        }
        .tint(DesignTokens.Palette.accent)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Palette.background.ignoresSafeArea())
        .navigationTitle("기상 알람")
        .environment(\.timeZone, Calendar.seoul.timeZone)
    }
}

#Preview {
    NavigationStack {
        WakeAlarmSettingsView(viewModel: AppDependencies.preview().makeWakeAlarmSettingsViewModel())
    }
    .preferredColorScheme(.dark)
}
