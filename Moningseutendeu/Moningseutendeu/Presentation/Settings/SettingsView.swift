import SwiftUI

/// 설정 첫 화면. 정류장 추가, 미세먼지 측정소, 알림 설정으로 들어간다.
struct SettingsView: View {
    @State private var stopSearchViewModel: StopSearchViewModel
    @State private var airQualityStationViewModel: AirQualityStationViewModel
    @State private var notificationViewModel: NotificationSettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var wakeAlarmViewModel: WakeAlarmSettingsViewModel

    init(stopSearchViewModel: StopSearchViewModel, airQualityStationViewModel: AirQualityStationViewModel, notificationViewModel: NotificationSettingsViewModel, wakeAlarmViewModel: WakeAlarmSettingsViewModel) {
        _wakeAlarmViewModel = State(initialValue: wakeAlarmViewModel)
        _stopSearchViewModel = State(initialValue: stopSearchViewModel)
        _airQualityStationViewModel = State(initialValue: airQualityStationViewModel)
        _notificationViewModel = State(initialValue: notificationViewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    StopSearchView(viewModel: stopSearchViewModel)
                } label: {
                    Label("정류장 추가", systemImage: DesignTokens.Symbol.starFilled)
                }
                NavigationLink {
                    AirQualityStationView(viewModel: airQualityStationViewModel)
                } label: {
                    LabeledContent {
                        Text(airQualityStationViewModel.selectedName)
                    } label: {
                        Label("미세먼지 측정소", systemImage: DesignTokens.Symbol.airQuality)
                    }
                }
                NavigationLink {
                    WakeAlarmSettingsView(viewModel: wakeAlarmViewModel)
                } label: {
                    Label("기상 알람", systemImage: DesignTokens.Symbol.alarm)
                }
                NavigationLink {
                    NotificationSettingsView(viewModel: notificationViewModel)
                } label: {
                    Label("알림", systemImage: DesignTokens.Symbol.bell)
                }
            }
            .scrollContentBackground(.hidden)
            .background(DesignTokens.Palette.background.ignoresSafeArea())
            .navigationTitle("설정")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { dismiss() }
                }
            }
        }
        .tint(DesignTokens.Palette.accent)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    SettingsView(
        stopSearchViewModel: dependencies.makeStopSearchViewModel(),
        airQualityStationViewModel: dependencies.makeAirQualityStationViewModel(),
        notificationViewModel: dependencies.makeNotificationSettingsViewModel(),
        wakeAlarmViewModel: dependencies.makeWakeAlarmSettingsViewModel()
    )
}
