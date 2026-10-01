import SwiftUI

/// 현재 기온·날씨·최고/최저·미세먼지 칩. 오래된 값은 흐리게 보여준다.
struct StandWeatherView: View {
    let panel: StandDisplayModel.WeatherPanel

    @Environment(\.standPalette) private var palette
    @Environment(\.standScale) private var scale

    private typealias Tokens = DesignTokens.Stand

    var body: some View {
        switch panel {
        case .placeholder:
            placeholder
        case .content(let weather, let isDimmed):
            content(weather)
                .opacity(isDimmed ? DesignTokens.Opacity.stale : 1)
        case .unavailable(let message):
            Text(message)
                .font(.system(size: Tokens.FontSize.condition * scale, weight: .semibold))
                .foregroundStyle(palette.secondary)
        }
    }

    private var placeholder: some View {
        VStack(alignment: .trailing, spacing: Tokens.Spacing.skeleton * scale) {
            skeleton(Tokens.Skeleton.temperature, radius: Tokens.Radius.banner)
            skeleton(Tokens.Skeleton.conditionLine, radius: Tokens.Radius.skeletonText)
            skeleton(Tokens.Skeleton.rangeLine, radius: Tokens.Radius.skeletonText)
            skeleton(Tokens.Skeleton.chips, radius: Tokens.Radius.banner)
        }
    }

    private func skeleton(_ size: CGSize, radius: CGFloat) -> some View {
        SkeletonBlock(width: size.width * scale, height: size.height * scale, cornerRadius: radius * scale, color: palette.skeleton)
    }

    private func content(_ weather: StandDisplayModel.Weather) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(spacing: Tokens.Spacing.weatherSymbolToTemperature * scale) {
                weatherSymbol(weather.symbol)
                let fontSize = Tokens.FontSize.temperature * scale
                Text(weather.temperatureText)
                    .font(.system(size: fontSize, weight: .semibold))
                    .monospacedDigit()
                    .tracking(Tokens.Tracking.temperature * scale)
                    .foregroundStyle(palette.text)
                    .lineHeight(fontSize: fontSize, multiple: Tokens.LineHeight.temperature)
            }
            Text(weather.conditionText)
                .font(.system(size: Tokens.FontSize.condition * scale, weight: .semibold))
                .foregroundStyle(palette.text)
                .padding(.top, Tokens.Spacing.conditionTop * scale)
            Text(weather.rangeText)
                .font(.system(size: Tokens.FontSize.temperatureRange * scale, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(palette.secondary)
                .padding(.top, Tokens.Spacing.rangeTop * scale)
            HStack(spacing: Tokens.Spacing.chips * scale) {
                airQualityChip(weather.pm10)
                airQualityChip(weather.pm25)
            }
            .padding(.top, Tokens.Spacing.chipsTop * scale)
        }
        .lineLimit(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(weather.accessibilityLabel)
    }

    private func weatherSymbol(_ symbol: StandDisplayModel.WeatherSymbol) -> some View {
        let image = Image(systemName: Self.symbolName(symbol))
            .font(.system(size: Tokens.Size.weatherSymbol * scale))
        return Group {
            if palette.theme == .night {
                image.symbolRenderingMode(.hierarchical).foregroundStyle(palette.accent)
            } else {
                image.symbolRenderingMode(.multicolor)
            }
        }
        .accessibilityHidden(true)
    }

    private func airQualityChip(_ chip: StandDisplayModel.AirQualityChip) -> some View {
        HStack(spacing: Tokens.Spacing.chipContent * scale) {
            Circle()
                .fill(palette.airQualityColor(for: chip.level))
                .frame(width: Tokens.Size.airQualityDot * scale, height: Tokens.Size.airQualityDot * scale)
            Text(chip.label)
        }
        .font(.system(size: Tokens.FontSize.airQualityChip * scale, weight: .semibold))
        .foregroundStyle(palette.text)
        .padding(Tokens.Padding.chip.scaled(scale))
        .background(palette.card, in: Capsule())
        .fixedSize()
    }

    static func symbolName(_ symbol: StandDisplayModel.WeatherSymbol) -> String {
        switch symbol {
        case .sun: DesignTokens.Symbol.sun
        case .moon: DesignTokens.Symbol.moon
        case .cloudSun: DesignTokens.Symbol.cloudSun
        case .cloudMoon: DesignTokens.Symbol.cloudMoon
        case .cloud: DesignTokens.Symbol.cloud
        case .rain: DesignTokens.Symbol.rain
        case .snow: DesignTokens.Symbol.snow
        }
    }
}
