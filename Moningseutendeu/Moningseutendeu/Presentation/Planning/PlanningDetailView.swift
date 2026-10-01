import SwiftUI

/// 오른쪽 상세: 경로별 소요 시간 비교 + 요일별 루틴.
struct PlanningDetailView: View {
    let viewModel: PlanningViewModel
    let display: PlanningDisplayModel

    private typealias Tokens = DesignTokens.Planning

    var body: some View {
        switch display.content {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView(message, systemImage: DesignTokens.Symbol.wifiOff)
        case .empty:
            ContentUnavailableView {
                Label("경로가 없어요", systemImage: DesignTokens.Symbol.route)
            } description: {
                Text("출발지와 이동 방법을 입력해서 출근 경로를 만들어 보세요.")
            } actions: {
                Button("경로 추가", action: viewModel.addRoute)
                    .buttonStyle(.borderedProminent)
                    .tint(DesignTokens.Palette.accent)
                    .foregroundStyle(DesignTokens.Palette.textOnAccent)
            }
        case .loaded:
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
                    if let detail = display.detail {
                        header(detail, legend: display.legend)
                        VStack(spacing: DesignTokens.Spacing.m) {
                            ForEach(detail.options) { option in
                                RouteOptionRowView(option: option)
                            }
                        }
                    }
                    RoutineEditorView(
                        weekdays: display.weekdays,
                        summary: display.routineSummary,
                        routine: display.routine,
                        onSelectDay: viewModel.selectWeekday(_:),
                        onToggle: viewModel.toggleSelectedWeekday
                    )
                    .padding(.top, DesignTokens.Spacing.s)
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func header(_ detail: PlanningDisplayModel.Detail, legend: [PlanningDisplayModel.LegendItem]) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .bottom, spacing: DesignTokens.Spacing.xxl) {
                titleBlock(detail)
                editButton
                Spacer(minLength: 0)
                SegmentLegendView(items: legend)
            }
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.m) {
                HStack(alignment: .firstTextBaseline) {
                    titleBlock(detail)
                    Spacer(minLength: 0)
                    editButton
                }
                SegmentLegendView(items: legend)
            }
        }
    }

    private var editButton: some View {
        Button("편집", action: viewModel.editSelectedRoute)
            .font(.system(size: Tokens.FontSize.subtitle))
            .foregroundStyle(DesignTokens.Palette.accent)
            .accessibilityIdentifier(AppConstants.AccessibilityID.editRouteButton)
    }

    private func titleBlock(_ detail: PlanningDisplayModel.Detail) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(detail.title)
                .font(.system(size: Tokens.FontSize.title, weight: .bold))
                .tracking(Tokens.Tracking.title)
            Text(detail.subtitle)
                .font(.system(size: Tokens.FontSize.subtitle))
                .foregroundStyle(DesignTokens.Palette.textSecondary)
        }
        .lineLimit(1)
        .fixedSize()
    }
}

/// 도보·대기·버스·지하철·환승 범례
struct SegmentLegendView: View {
    let items: [PlanningDisplayModel.LegendItem]

    private typealias Tokens = DesignTokens.Planning

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.ml) {
            ForEach(items) { item in
                HStack(spacing: DesignTokens.Spacing.xs) {
                    SegmentSwatch(kind: item.kind)
                        .frame(width: Tokens.legendSwatch.width, height: Tokens.legendSwatch.height)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xs))
                    Text(item.name)
                }
            }
        }
        .font(.system(size: Tokens.FontSize.caption))
        .foregroundStyle(DesignTokens.Palette.textSecondary)
        .fixedSize()
        .accessibilityHidden(true)
    }
}

/// 구간 종류별 색 조각. 대기는 사선 줄무늬.
struct SegmentSwatch: View {
    let kind: RouteSegment.Kind

    var body: some View {
        switch kind {
        case .walk: DesignTokens.Segment.walk
        case .wait:
            StripedFill(
                stripeColor: DesignTokens.Segment.waitStripe,
                gapColor: DesignTokens.Segment.waitGap,
                stripeWidth: DesignTokens.Planning.waitStripeWidth
            )
        case .bus: DesignTokens.Segment.bus
        case .subway: DesignTokens.Segment.subway
        case .transfer: DesignTokens.Segment.transfer
        }
    }
}
