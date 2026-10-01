import SwiftUI

/// 알림 설정 화면.
struct NotificationSettingsView: View {
    @Bindable var viewModel: NotificationSettingsViewModel

    private typealias Tokens = DesignTokens.Settings

    var body: some View {
        Form {
            Section {
                Toggle("출발 알림", isOn: $viewModel.isDepartureAlertOn)
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("출발 몇 분 전에 알릴까요")
                        .font(.system(size: Tokens.FontSize.callout))
                        .foregroundStyle(DesignTokens.Palette.textSecondary)
                    Picker("알림 시점", selection: $viewModel.leadMinutes) {
                        ForEach(viewModel.leadOptions, id: \.self) { minutes in
                            Text(viewModel.leadText(minutes)).tag(minutes)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .padding(.vertical, DesignTokens.Spacing.xxs)
                .disabled(!viewModel.isDepartureAlertOn)
                .opacity(viewModel.isDepartureAlertOn ? 1 : DesignTokens.Opacity.disabled)
                Toggle("놓칠 것 같으면 다시 알림", isOn: $viewModel.isMissAlertOn)
            } header: {
                Text("출발")
            } footer: {
                Text("도착 예정이 바뀌면 알림 시각도 함께 조정돼요.")
            }

            Section("날씨") {
                Toggle("우산 알림", isOn: $viewModel.isUmbrellaAlertOn)
                LabeledContent("강수확률 기준", value: viewModel.rainThresholdText)
                Toggle("미세먼지 나쁨 알림", isOn: $viewModel.isDustAlertOn)
            }

            Section("미리보기") {
                NotificationPreviewCard(title: viewModel.previewTitle, message: viewModel.previewBody)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
        .tint(DesignTokens.Palette.accent)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Palette.background.ignoresSafeArea())
        .navigationTitle("알림")
    }
}

/// 잠금 화면 알림처럼 보이는 미리보기 카드
struct NotificationPreviewCard: View {
    let title: String
    let message: String

    private typealias Tokens = DesignTokens.Settings

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.m) {
            Image(systemName: DesignTokens.Symbol.appIcon)
                .font(.system(size: Tokens.FontSize.body, weight: .semibold))
                .foregroundStyle(DesignTokens.Palette.textOnAccent)
                .frame(width: Tokens.previewIconSize, height: Tokens.previewIconSize)
                .background(DesignTokens.Palette.accent, in: RoundedRectangle(cornerRadius: Tokens.previewIconRadius, style: .continuous))
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxxs) {
                HStack {
                    Text(title)
                        .font(.system(size: Tokens.FontSize.callout, weight: .bold))
                    Spacer()
                    Text("지금")
                        .font(.system(size: Tokens.FontSize.footnote))
                        .foregroundStyle(DesignTokens.Palette.textTertiary)
                }
                Text(message)
                    .font(.system(size: Tokens.FontSize.callout))
                    .foregroundStyle(DesignTokens.Palette.textPreviewBody)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DesignTokens.Spacing.ml)
        .background(DesignTokens.Palette.surfaceGrouped, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.large, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView(viewModel: AppDependencies.preview().makeNotificationSettingsViewModel())
    }
    .preferredColorScheme(.dark)
}
