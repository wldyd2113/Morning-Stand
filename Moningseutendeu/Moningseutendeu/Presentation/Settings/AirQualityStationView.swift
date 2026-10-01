import SwiftUI

/// 미세먼지 측정소 고르기. 집과 가까운 구 이름을 고르면 된다.
struct AirQualityStationView: View {
    let viewModel: AirQualityStationViewModel

    var body: some View {
        List {
            Section {
                if let message = viewModel.errorMessage {
                    Text(message).foregroundStyle(DesignTokens.Palette.textSecondary)
                } else if viewModel.stations.value == nil {
                    ProgressView().frame(maxWidth: .infinity)
                }
                ForEach(viewModel.stations.value ?? [], id: \.self) { name in
                    Button { viewModel.select(name) } label: {
                        HStack {
                            Text(name).foregroundStyle(DesignTokens.Palette.textPrimary)
                            Spacer()
                            if name == viewModel.selectedName {
                                Image(systemName: DesignTokens.Symbol.checkmark)
                                    .foregroundStyle(DesignTokens.Palette.accent)
                            }
                        }
                    }
                    .accessibilityAddTraits(name == viewModel.selectedName ? .isSelected : [])
                }
            } footer: {
                Text("집과 가까운 측정소를 고르세요. 스탠드 화면의 미세먼지에 쓰여요.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Palette.background.ignoresSafeArea())
        .navigationTitle("미세먼지 측정소")
        .task { await viewModel.load() }
    }
}

#Preview {
    NavigationStack {
        AirQualityStationView(viewModel: AppDependencies.preview().makeAirQualityStationViewModel())
    }
    .preferredColorScheme(.dark)
}
