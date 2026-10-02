import MapKit
import SwiftUI

/// 주변 정류장 지도. 핀을 누르면 아래 시트에 그 정류장의 도착 정보를 보여준다.
struct NearbyMapView: View {
    let viewModel: NearbyStopsViewModel

    @State private var camera: MapCameraPosition = .automatic

    private typealias Tokens = DesignTokens.Nearby
    private typealias SettingsTokens = DesignTokens.Settings

    var body: some View {
        let display = viewModel.display
        Map(position: $camera) {
            UserAnnotation()
            if let home = display.homeCoordinate {
                Annotation("집", coordinate: home.locationCoordinate) {
                    Image(systemName: DesignTokens.Symbol.home)
                        .font(.system(size: Tokens.FontSize.pinSymbol, weight: .bold))
                        .foregroundStyle(DesignTokens.Palette.textOnAccent)
                        .frame(width: Tokens.homePinSize, height: Tokens.homePinSize)
                        .background(DesignTokens.Palette.textPrimary, in: Circle())
                }
            }
            ForEach(display.pins) { pin in
                Annotation(pin.name, coordinate: pin.coordinate.locationCoordinate) {
                    stopPin(pin)
                }
                .annotationTitles(pin.isSelected ? .visible : .hidden)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .overlay(alignment: .topLeading) { topBar(display) }
        .overlay(alignment: .bottom) { emptyMessage(display) }
        .navigationTitle(display.resultSummary ?? String(localized: "주변 정류장"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .task(id: viewModel.selectedStopID) { await viewModel.loadSelection() }
        // 다시 찾으면 새 정류장이 모두 보이게 지도를 맞춘다
        .onChange(of: display.searchGeneration) {
            withAnimation(DesignTokens.Animation.sheet) { camera = .automatic }
        }
        .sheet(isPresented: Binding(get: { display.selection != nil }, set: { if !$0 { viewModel.clearSelection() } })) {
            NearbyStopSheetView(viewModel: viewModel)
                .presentationDetents([.fraction(Tokens.sheetMediumFraction), .large])
                // 시트가 중간 높이일 때도 지도를 움직이고 다른 핀을 누를 수 있게 한다
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(Tokens.sheetMediumFraction)))
                .presentationBackground(DesignTokens.Palette.surfaceCard)
                .preferredColorScheme(.dark)
        }
        .accessibilityIdentifier(AppConstants.AccessibilityID.nearbyMap)
    }

    private func stopPin(_ pin: NearbyDisplayModel.Pin) -> some View {
        let size = pin.isSelected ? Tokens.selectedPinSize : Tokens.pinSize
        return Button { viewModel.toggleSelection(stopID: pin.id) } label: {
            Image(systemName: pin.isFavorite ? DesignTokens.Symbol.starFilled : DesignTokens.Symbol.bus)
                .font(.system(size: pin.isSelected ? Tokens.FontSize.selectedPinSymbol : Tokens.FontSize.pinSymbol, weight: .bold))
                .foregroundStyle(pin.isSelected ? DesignTokens.Palette.textOnAccent : DesignTokens.Segment.bus)
                .frame(width: size, height: size)
                .background(pin.isSelected ? DesignTokens.Palette.accent : DesignTokens.Palette.surfaceGrouped, in: Circle())
                .overlay(Circle().strokeBorder(pin.isSelected ? DesignTokens.Palette.textOnAccent : DesignTokens.Segment.bus, lineWidth: Tokens.pinRingWidth))
                .animation(DesignTokens.Animation.selection, value: pin.isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(pin.name))
        .accessibilityAddTraits(pin.isSelected ? .isSelected : [])
    }

    private func topBar(_ display: NearbyDisplayModel) -> some View {
        HStack(spacing: DesignTokens.Spacing.s) {
            Button {
                Task { await viewModel.findNearby() }
            } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    if display.isLocating {
                        ProgressView().tint(DesignTokens.Palette.textOnAccent)
                    } else {
                        Image(systemName: DesignTokens.Symbol.location)
                    }
                    Text("다시 찾기")
                }
                .font(.system(size: SettingsTokens.FontSize.callout, weight: .semibold))
                .foregroundStyle(DesignTokens.Palette.textOnAccent)
                .padding(Tokens.messagePadding)
                .background(DesignTokens.Palette.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(display.isLocating)
            if let locationText = display.locationText {
                Text(locationText)
                    .font(.system(size: SettingsTokens.FontSize.footnote))
                    .foregroundStyle(DesignTokens.Palette.textSecondary)
                    .padding(Tokens.messagePadding)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .padding(Tokens.mapOverlayPadding)
    }

    /// "다시 찾기" 결과가 없거나 실패했을 때
    @ViewBuilder
    private func emptyMessage(_ display: NearbyDisplayModel) -> some View {
        if let message = display.message {
            Text(message)
                .font(.system(size: SettingsTokens.FontSize.callout))
                .multilineTextAlignment(.center)
                .padding(Tokens.messagePadding)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
                .padding(Tokens.mapOverlayPadding)
        }
    }
}

#Preview {
    let viewModel = AppDependencies.preview().makeNearbyStopsViewModel()
    NavigationStack {
        NearbyMapView(viewModel: viewModel)
    }
    .task { await viewModel.findNearby() }
    .preferredColorScheme(.dark)
}
