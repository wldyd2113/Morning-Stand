import SwiftUI

/// 경로 편집의 정류장 고르기 화면.
struct StopPickerView: View {
    @Bindable var viewModel: StopPickerViewModel

    var body: some View {
        List {
            Section {
                Picker("종류", selection: $viewModel.transport) {
                    Text("버스 정류장").tag(TransportKind.bus)
                    Text("지하철역").tag(TransportKind.subway)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            if viewModel.isSearching {
                Section("검색 결과") {
                    if viewModel.isLoading && viewModel.resultRows.isEmpty {
                        ProgressView().frame(maxWidth: .infinity)
                    } else if let message = viewModel.message {
                        Text(message).foregroundStyle(DesignTokens.Palette.textSecondary)
                    }
                    ForEach(viewModel.resultRows) { row in
                        rowButton(row)
                    }
                }
            } else {
                Section {
                    if viewModel.favoriteRows.isEmpty {
                        Text("즐겨찾기한 정류장이 없어요. 위 검색창에 이름을 입력하세요.")
                            .foregroundStyle(DesignTokens.Palette.textSecondary)
                    }
                    ForEach(viewModel.favoriteRows) { row in
                        rowButton(row)
                    }
                } header: {
                    Text("즐겨찾기")
                }
            }
        }
        .searchable(text: $viewModel.query, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("정류장·역 이름"))
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Palette.background.ignoresSafeArea())
        .navigationTitle("정류장 선택")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: viewModel.searchKey) { await viewModel.search() }
    }

    private func rowButton(_ row: StopPickerViewModel.Row) -> some View {
        Button { viewModel.select(row.id) } label: {
            HStack(spacing: DesignTokens.Spacing.m) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxxs) {
                    Text(row.name)
                        .foregroundStyle(DesignTokens.Palette.textPrimary)
                    if !row.detail.isEmpty {
                        Text(row.detail)
                            .font(.system(size: DesignTokens.Settings.FontSize.subheadline))
                            .foregroundStyle(DesignTokens.Palette.textSecondary)
                    }
                }
                Spacer()
                if row.isFavorite {
                    Image(systemName: DesignTokens.Symbol.starFilled)
                        .foregroundStyle(DesignTokens.Palette.accent)
                        .accessibilityLabel(Text("즐겨찾기"))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        StopPickerView(viewModel: StopPickerViewModel(
            favorites: SampleTransitStopRepository.favorites,
            initialKind: .bus,
            repository: SampleTransitStopRepository(),
            dateProvider: SystemDateProvider(),
            clock: ContinuousClock(),
            onSelect: { _ in }
        ))
    }
    .preferredColorScheme(.dark)
}
