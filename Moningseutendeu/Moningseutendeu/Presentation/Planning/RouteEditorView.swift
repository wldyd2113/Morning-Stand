import SwiftUI

/// 경로 추가·편집 화면. 이동 방법마다 정류장·노선·탑승 시간을 입력하면 구간 막대가 만들어진다.
struct RouteEditorView: View {
    @Bindable var viewModel: RouteEditorViewModel
    @State private var isConfirmingDelete = false

    private typealias Limits = PolicyConstants.RouteEditor

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("이름 (예: 집 → 회사)", text: $viewModel.name)
                    TextField("출발지 (예: 불광동)", text: $viewModel.origin)
                    TextField("도착지 (예: 광화문)", text: $viewModel.destination)
                }

                Section("출발") {
                    DatePicker("출발 시각", selection: $viewModel.departure, displayedComponents: .hourAndMinute)
                    weekdayPicker
                }

                ForEach(Array($viewModel.options.enumerated()), id: \.element.id) { index, $option in
                    optionSection(index: index, option: $option)
                }

                Section {
                    Button {
                        viewModel.addOption()
                    } label: {
                        Label("이동 방법 추가", systemImage: DesignTokens.Symbol.plus)
                    }
                } footer: {
                    if let message = viewModel.validationMessage ?? viewModel.saveErrorMessage {
                        Text(message).foregroundStyle(DesignTokens.Palette.accent)
                    }
                }

                if viewModel.isEditing {
                    Section {
                        Button("경로 삭제", role: .destructive) { isConfirmingDelete = true }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DesignTokens.Palette.background.ignoresSafeArea())
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소", action: viewModel.cancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", action: viewModel.save)
                        .disabled(!viewModel.canSave)
                }
            }
            .confirmationDialog("이 경로를 삭제할까요?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("삭제", role: .destructive, action: viewModel.delete)
            }
            .navigationDestination(isPresented: Binding(
                get: { viewModel.stopPicker != nil },
                set: { if !$0 { viewModel.closeStopPicker() } }
            )) {
                if let picker = viewModel.stopPicker {
                    StopPickerView(viewModel: picker)
                }
            }
        }
        .environment(\.timeZone, Calendar.seoul.timeZone)
        .tint(DesignTokens.Palette.accent)
        .preferredColorScheme(.dark)
        .task { await viewModel.load() }
    }

    private var weekdayPicker: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(Weekday.displayOrder, id: \.self) { weekday in
                let isSelected = viewModel.isSelected(weekday)
                Button { viewModel.toggleWeekday(weekday) } label: {
                    Text(PlanningDisplayMapper.shortName(weekday, calendar: .seoul))
                        .font(.system(size: DesignTokens.Settings.FontSize.callout, weight: .bold))
                        .foregroundStyle(isSelected ? DesignTokens.Palette.textOnAccent : DesignTokens.Palette.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: DesignTokens.Settings.starButtonSize)
                        .background(isSelected ? DesignTokens.Palette.accent : DesignTokens.Palette.surfaceElevated, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private func optionSection(index: Int, option: Binding<RouteEditorViewModel.OptionDraft>) -> some View {
        let optionID = option.wrappedValue.id
        return Section {
            ForEach(Array(option.legs.enumerated()), id: \.element.id) { legIndex, $leg in
                legRows(legIndex: legIndex, leg: $leg, optionID: optionID)
                if legIndex == 0 {
                    Stepper("첫 정류장 대기 \(option.wrappedValue.waitMinutes)분", value: option.waitMinutes, in: Limits.minimumMinutes...Limits.maximumMinutes)
                }
            }
            Stepper("하차 후 도보 \(option.wrappedValue.finalWalkMinutes)분", value: option.finalWalkMinutes, in: Limits.minimumMinutes...Limits.maximumMinutes)
            if viewModel.canAddTransfer(optionID) {
                Button {
                    viewModel.addTransfer(optionID)
                } label: {
                    Label("환승 추가", systemImage: DesignTokens.Symbol.plus)
                }
            }
            if viewModel.options.count > 1 {
                Button("이 이동 방법 삭제", role: .destructive) { viewModel.removeOption(optionID) }
            }
        } header: {
            Text("이동 방법 \(index + 1)")
        } footer: {
            Text(viewModel.summary(for: option.wrappedValue))
        }
    }

    @ViewBuilder
    private func legRows(legIndex: Int, leg: Binding<RouteEditorViewModel.LegDraft>, optionID: RouteEditorViewModel.OptionDraft.ID) -> some View {
        let legID = leg.wrappedValue.id
        let draft = leg.wrappedValue

        if legIndex > 0 {
            Stepper("환승 이동 \(draft.accessMinutes)분", value: leg.accessMinutes, in: Limits.minimumMinutes...Limits.maximumMinutes)
        }
        Button {
            viewModel.openStopPicker(optionID: optionID, legID: legID)
        } label: {
            LabeledContent(legIndex == 0 ? "타는 정류장" : "환승 정류장") {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Text(viewModel.stopTitle(for: draft) ?? String(localized: "검색해서 선택"))
                        .foregroundStyle(draft.stopID == nil ? DesignTokens.Palette.accent : DesignTokens.Palette.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                    Image(systemName: DesignTokens.Symbol.chevronRight)
                        .font(.system(size: DesignTokens.Settings.FontSize.footnote, weight: .semibold))
                        .foregroundStyle(DesignTokens.Palette.textTertiary)
                }
            }
            .foregroundStyle(DesignTokens.Palette.textPrimary)
        }
        .task(id: "\(draft.kind.rawValue)-\(draft.stopID ?? "")") {
            await viewModel.loadRoutes(for: draft)
        }
        Picker("노선", selection: leg.routeKey) {
            Text("선택").tag(String?.none)
            ForEach(viewModel.routeNames(for: draft), id: \.self) { name in
                Text(name).tag(Optional(name))
            }
        }
        .disabled(draft.stopID == nil)
        if let message = viewModel.routesMessage(for: draft) {
            Text(message)
                .font(.system(size: DesignTokens.Settings.FontSize.footnote))
                .foregroundStyle(DesignTokens.Palette.textSecondary)
        }
        if legIndex == 0 {
            Stepper("집에서 정류장까지 \(leg.wrappedValue.accessMinutes)분", value: leg.accessMinutes, in: Limits.minimumMinutes...Limits.maximumMinutes)
        }
        Stepper("탑승 \(leg.wrappedValue.rideMinutes)분", value: leg.rideMinutes, in: 1...Limits.maximumMinutes)
        if legIndex > 0 {
            Button("이 환승 구간 삭제", role: .destructive) { viewModel.removeLeg(optionID: optionID, legID: legID) }
        }
    }
}

#Preview("새 경로") {
    RouteEditorView(viewModel: AppDependencies.preview().makeRouteEditorViewModel(route: nil, onFinish: {}))
}
