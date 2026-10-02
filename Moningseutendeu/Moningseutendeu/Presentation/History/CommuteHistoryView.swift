import Charts
import SwiftUI

/// 출근 기록·통계 탭: 요약 타일, 요일별 평균 소요 시간, 출발 시각 추이, 최근 기록.
struct CommuteHistoryView: View {
    let viewModel: CommuteHistoryViewModel

    @State private var selectedWeekday: String?

    private typealias Tokens = DesignTokens.History
    private typealias SettingsTokens = DesignTokens.Settings

    var body: some View {
        let display = viewModel.display
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    Text(display.periodText)
                        .font(.system(size: SettingsTokens.FontSize.callout))
                        .foregroundStyle(DesignTokens.Palette.textSecondary)
                    tiles(display.tiles)
                    if let error = display.actionError {
                        Text(error)
                            .font(.system(size: SettingsTokens.FontSize.footnote, weight: .semibold))
                            .foregroundStyle(DesignTokens.Palette.error)
                    }
                    if let message = display.message {
                        Text(message)
                            .font(.system(size: SettingsTokens.FontSize.callout))
                            .foregroundStyle(DesignTokens.Palette.textSecondary)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .padding(.top, DesignTokens.Spacing.xl)
                    } else if display.isLoading && display.rows.isEmpty {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        if !display.weekdayBars.isEmpty { weekdayChart(display.weekdayBars) }
                        if !display.departurePoints.isEmpty { departureChart(display) }
                        recentRows(display.rows)
                    }
                }
                .padding(.horizontal, SettingsTokens.screenPadding)
                .padding(.bottom, DesignTokens.Spacing.xxl)
            }
            .background(DesignTokens.Palette.background.ignoresSafeArea())
            .foregroundStyle(DesignTokens.Palette.textPrimary)
            .navigationTitle("출근 기록")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await viewModel.recordLeavingNow() }
                    } label: {
                        Label("지금 출발", systemImage: DesignTokens.Symbol.door)
                    }
                    .disabled(viewModel.isRecording)
                    .accessibilityIdentifier(AppConstants.AccessibilityID.historyLeaveNowButton)
                }
            }
            .task { await viewModel.load() }
        }
        .tint(DesignTokens.Palette.accent)
        .accessibilityIdentifier(AppConstants.AccessibilityID.historyRoot)
    }

    // MARK: - 요약

    private func tiles(_ tiles: [CommuteHistoryDisplayModel.Tile]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: Tokens.tileMinWidth), spacing: DesignTokens.Spacing.m, alignment: .top)], alignment: .leading, spacing: DesignTokens.Spacing.m) {
            ForEach(tiles) { tile in
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    Text(tile.label)
                        .font(.system(size: Tokens.FontSize.tileLabel))
                        .foregroundStyle(DesignTokens.Palette.textSecondary)
                    Text(tile.value)
                        .font(.system(size: Tokens.FontSize.tileValue, weight: .bold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(DesignTokens.History.tileValueMinimumScale)
                    // 설명이 없어도 줄을 비워 둬서 타일 높이를 맞춘다
                    Text(tile.detail ?? " ")
                        .font(.system(size: Tokens.FontSize.tileLabel))
                        .foregroundStyle(DesignTokens.Palette.textTertiary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Tokens.tilePadding)
                .background(DesignTokens.Palette.surfaceGrouped, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous))
                .accessibilityElement(children: .combine)
            }
        }
    }

    // MARK: - 차트

    /// 요일별 평균 집 → 탑승 시간. 계열이 하나라 범례 대신 제목으로 설명하고, 값은 막대를 눌렀을 때만 보여준다.
    private func weekdayChart(_ bars: [CommuteHistoryDisplayModel.WeekdayBar]) -> some View {
        chartSection(title: "요일별 평균 소요 시간", subtitle: "집을 나서서 차량에 탈 때까지 (분)") {
            Chart(bars) { bar in
                BarMark(
                    x: .value("요일", bar.label),
                    y: .value("평균(분)", bar.averageMinutes),
                    width: .fixed(Tokens.barWidth)
                )
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: Tokens.barCornerRadius, topTrailingRadius: Tokens.barCornerRadius))
                .foregroundStyle(selectedWeekday == nil || selectedWeekday == bar.label ? DesignTokens.Palette.accent : DesignTokens.Palette.accent.opacity(DesignTokens.Opacity.disabled))
                .accessibilityLabel(Text(bar.label))
                .accessibilityValue(Text(bar.valueText))
                if selectedWeekday == bar.label {
                    RuleMark(x: .value("요일", bar.label))
                        .foregroundStyle(.clear)
                        .annotation(position: .top, overflowResolution: .init(x: .fit, y: .disabled)) {
                            Text(bar.valueText)
                                .font(.system(size: Tokens.FontSize.rowDetail, weight: .semibold))
                                .foregroundStyle(DesignTokens.Palette.textPrimary)
                                .padding(DesignTokens.History.calloutPadding)
                                .background(DesignTokens.Palette.surfaceElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.s))
                        }
                }
            }
            .chartXSelection(value: $selectedWeekday)
            .chartYAxis { recessiveYAxis() }
            .chartXAxis {
                AxisMarks { _ in AxisValueLabel().foregroundStyle(DesignTokens.Palette.textSecondary) }
            }
        }
    }

    /// 날짜별 집을 나선 시각. 놓친 날은 색과 모양(빈 원)을 함께 바꾼다.
    private func departureChart(_ display: CommuteHistoryDisplayModel) -> some View {
        chartSection(title: "집을 나선 시각", subtitle: "● 탑승 · ○ 안내한 차를 놓침") {
            Chart(display.departurePoints) { point in
                LineMark(x: .value("날짜", point.day, unit: .day), y: .value("출발", point.minuteOfDay))
                    .foregroundStyle(DesignTokens.Palette.textTertiary)
                    .lineStyle(StrokeStyle(lineWidth: Tokens.lineWidth))
                    .interpolationMethod(.monotone)
                PointMark(x: .value("날짜", point.day, unit: .day), y: .value("출발", point.minuteOfDay))
                    .symbol {
                        if point.missed {
                            Circle()
                                .strokeBorder(DesignTokens.Palette.error, lineWidth: Tokens.lineWidth)
                                .background(Circle().fill(DesignTokens.Palette.surfaceCard))
                                .frame(width: Tokens.pointDiameter, height: Tokens.pointDiameter)
                        } else {
                            Circle()
                                .fill(DesignTokens.Palette.accent)
                                .frame(width: Tokens.pointDiameter, height: Tokens.pointDiameter)
                        }
                    }
                    .accessibilityLabel(Text(point.accessibilityText))
            }
            .chartYScale(domain: display.departureAxisMinutes)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(DesignTokens.Palette.separatorGrouped)
                    AxisValueLabel {
                        if let minute = value.as(Int.self) {
                            Text(viewModel.axisTimeText(minuteOfDay: minute))
                                .foregroundStyle(DesignTokens.Palette.textSecondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: DesignTokens.History.dayAxisStride)) { _ in
                    AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
                        .foregroundStyle(DesignTokens.Palette.textSecondary)
                }
            }
        }
    }

    private func recessiveYAxis() -> some AxisContent {
        AxisMarks(position: .leading) { _ in
            AxisGridLine().foregroundStyle(DesignTokens.Palette.separatorGrouped)
            AxisValueLabel().foregroundStyle(DesignTokens.Palette.textSecondary)
        }
    }

    private func chartSection(title: LocalizedStringKey, subtitle: LocalizedStringKey, @ViewBuilder chart: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Text(title)
                .font(.system(size: Tokens.FontSize.sectionTitle, weight: .bold))
            Text(subtitle)
                .font(.system(size: Tokens.FontSize.rowDetail))
                .foregroundStyle(DesignTokens.Palette.textTertiary)
            chart()
                .frame(height: Tokens.chartHeight)
                .padding(.top, DesignTokens.Spacing.s)
        }
        .padding(Tokens.chartPadding)
        .background(DesignTokens.Palette.surfaceCard, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous))
    }

    // MARK: - 최근 기록

    private func recentRows(_ rows: [CommuteHistoryDisplayModel.Row]) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
            Text("최근 기록")
                .font(.system(size: Tokens.FontSize.sectionTitle, weight: .bold))
            VStack(spacing: 0) {
                ForEach(rows) { row in
                    HStack(spacing: DesignTokens.Spacing.m) {
                        Image(systemName: row.missed ? DesignTokens.Symbol.missed : DesignTokens.Symbol.onTime)
                            .font(.system(size: Tokens.FontSize.rowDetail))
                            .foregroundStyle(row.missed ? DesignTokens.Palette.error : DesignTokens.Palette.liveIndicator)
                            .accessibilityLabel(row.missed ? Text("놓침") : Text("탑승"))
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxxs) {
                            Text(row.dateText)
                                .font(.system(size: Tokens.FontSize.row, weight: .semibold))
                            Text(row.detail)
                                .font(.system(size: Tokens.FontSize.rowDetail))
                                .foregroundStyle(DesignTokens.Palette.textSecondary)
                        }
                        Spacer()
                        Text(row.minutesText)
                            .font(.system(size: Tokens.FontSize.row, weight: .bold))
                            .monospacedDigit()
                    }
                    .padding(Tokens.rowPadding)
                    .contextMenu {
                        Button(role: .destructive) {
                            Task { await viewModel.delete(id: row.id) }
                        } label: {
                            Label("기록 삭제", systemImage: DesignTokens.Symbol.trash)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    if row.id != rows.last?.id {
                        Divider().overlay(DesignTokens.Palette.separatorGrouped)
                    }
                }
            }
            .background(DesignTokens.Palette.surfaceGrouped, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous))
        }
    }
}

#Preview {
    CommuteHistoryView(viewModel: AppDependencies.preview().makeCommuteHistoryViewModel())
        .preferredColorScheme(.dark)
}
