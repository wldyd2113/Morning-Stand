import SwiftUI

/// 정류장 검색 · 도보 시간 설정. 아래 시트에서 고른 정류장의 도보 시간과 알림 노선을 정한다.
struct StopSearchView: View {
    @Bindable var viewModel: StopSearchViewModel

    private typealias Tokens = DesignTokens.Settings

    var body: some View {
        let display = viewModel.display
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("자주 타는 정류장을\n추가하세요")
                    .font(.system(size: Tokens.FontSize.title, weight: .bold))
                    .tracking(DesignTokens.Planning.Tracking.title)
                Text("도보 시간은 출발 시각 계산에 쓰여요.")
                    .font(.system(size: Tokens.FontSize.callout))
                    .foregroundStyle(DesignTokens.Palette.textSecondary)
                    .padding(.top, DesignTokens.Spacing.xs)

                searchField
                    .padding(.top, DesignTokens.Spacing.lx)

                Picker("종류", selection: $viewModel.transport) {
                    Text("버스 정류장").tag(TransportKind.bus)
                    Text("지하철역").tag(TransportKind.subway)
                }
                .pickerStyle(.segmented)
                .padding(.top, DesignTokens.Spacing.m)

                results(display)
                    .padding(.top, DesignTokens.Spacing.s)
            }
            .padding(.horizontal, Tokens.screenPadding)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let selection = display.selection {
                StopDetailSheet(selection: selection, viewModel: viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(DesignTokens.Animation.sheet, value: display.selection != nil)
        .background(DesignTokens.Palette.background.ignoresSafeArea())
        .foregroundStyle(DesignTokens.Palette.textPrimary)
        .navigationTitle("정류장 추가")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: viewModel.searchKey) { await viewModel.search() }
        .task(id: viewModel.selectedStopID) { await viewModel.loadRoutesForSelection() }
    }

    private var searchField: some View {
        HStack(spacing: DesignTokens.Spacing.s) {
            Image(systemName: DesignTokens.Symbol.search)
                .foregroundStyle(DesignTokens.Palette.textTertiary)
            TextField("정류장·역 이름", text: $viewModel.query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .tint(DesignTokens.Palette.accent)
                .accessibilityIdentifier(AppConstants.AccessibilityID.stopSearchField)
        }
        .font(.system(size: Tokens.FontSize.body))
        .padding(.horizontal, DesignTokens.Spacing.m)
        .frame(height: Tokens.searchFieldHeight)
        .background(DesignTokens.Palette.surfaceGrouped, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous))
    }

    @ViewBuilder
    private func results(_ display: StopSearchDisplayModel) -> some View {
        if display.isLoading && display.rows.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, DesignTokens.Spacing.xxl)
        } else if let message = display.emptyMessage {
            Text(message)
                .font(.system(size: Tokens.FontSize.callout))
                .foregroundStyle(DesignTokens.Palette.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.top, DesignTokens.Spacing.xxl)
        } else {
            VStack(spacing: 0) {
                ForEach(display.rows) { row in
                    stopRow(row)
                }
            }
        }
    }

    private func stopRow(_ row: StopSearchDisplayModel.Row) -> some View {
        HStack(spacing: DesignTokens.Spacing.m) {
            Button { viewModel.toggleSelection(stopID: row.id) } label: {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxxs) {
                    Text(row.name)
                        .font(.system(size: Tokens.FontSize.body, weight: .semibold))
                        .foregroundStyle(DesignTokens.Palette.textPrimary)
                    Text(row.detail)
                        .font(.system(size: Tokens.FontSize.subheadline))
                        .foregroundStyle(DesignTokens.Palette.textSecondary)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(row.isSelected ? .isSelected : [])

            Button { viewModel.toggleFavorite(stopID: row.id) } label: {
                Image(systemName: row.isFavorite ? DesignTokens.Symbol.starFilled : DesignTokens.Symbol.star)
                    .font(.system(size: Tokens.FontSize.star))
                    .foregroundStyle(row.isFavorite ? DesignTokens.Palette.accent : DesignTokens.Palette.textDisabled)
                    .frame(width: Tokens.starButtonSize, height: Tokens.starButtonSize)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(row.isFavorite ? Text("즐겨찾기 해제") : Text("즐겨찾기"))
        }
        .padding(Tokens.stopRowPadding)
        .background(
            row.isSelected ? DesignTokens.Palette.surfaceGrouped : .clear,
            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
        )
        .padding(.horizontal, -Tokens.stopRowPadding.leading)
        .animation(DesignTokens.Animation.selection, value: row)
    }
}

#Preview {
    NavigationStack {
        StopSearchView(viewModel: AppDependencies.preview().makeStopSearchViewModel())
    }
    .preferredColorScheme(.dark)
}
