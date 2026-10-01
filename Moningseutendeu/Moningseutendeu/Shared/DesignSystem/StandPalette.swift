import SwiftUI

/// 스탠드 화면 색 묶음. 주간과 새벽·야간 저휘도 레드 테마 두 가지.
/// 시스템 다크 모드와 별개로 시각(`DisplayTheme`)에 따라 바뀐다.
struct StandPalette: Equatable {
    let theme: DisplayTheme
    let background: Color
    let text: Color
    let secondary: Color
    let dim: Color
    let line: Color
    let card: Color
    let cardStrong: Color
    let skeleton: Color
    let accent: Color
    let accentBackground: Color

    static let day = StandPalette(
        theme: .day,
        background: Color(hex: 0x000000),
        text: Color(hex: 0xF5F5F7),
        secondary: Color(hex: 0x98989F),
        dim: Color(hex: 0x636366),
        line: Color(hex: 0x1F1F22),
        card: Color(hex: 0x141416),
        cardStrong: Color(hex: 0x2C2C2E),
        skeleton: Color(hex: 0x1C1C1F),
        accent: Color(hex: 0xF4B04F),
        accentBackground: Color(hex: 0xF4B04F, opacity: 0.14)
    )

    static let night = StandPalette(
        theme: .night,
        background: Color(hex: 0x000000),
        text: Color(hex: 0xD9483B),
        secondary: Color(hex: 0x8A2A21),
        dim: Color(hex: 0x5A1A14),
        line: Color(hex: 0x200806),
        card: Color(hex: 0x140403),
        cardStrong: Color(hex: 0x220806),
        skeleton: Color(hex: 0x1C0604),
        accent: Color(hex: 0xD9483B),
        accentBackground: Color(hex: 0xD9483B, opacity: 0.12)
    )

    static func resolve(_ theme: DisplayTheme) -> StandPalette {
        switch theme {
        case .day: .day
        case .night: .night
        }
    }

    struct HeroColors: Equatable {
        let background: Color
        let foreground: Color
        let badge: Color
    }

    /// 히어로 카드 색. 야간에는 단계 색 대신 어두운 레드 계열로 통일한다.
    func heroColors(for urgency: DepartureUrgency) -> HeroColors {
        if theme == .night {
            return HeroColors(
                background: urgency == .now ? DesignTokens.Hero.nightNowBackground : DesignTokens.Hero.nightBackground,
                foreground: text,
                badge: DesignTokens.Hero.nightBadge
            )
        }
        switch urgency {
        case .relaxed:
            return HeroColors(background: DesignTokens.Hero.relaxed, foreground: DesignTokens.Hero.foregroundOnColor, badge: DesignTokens.Hero.badgeOnColor)
        case .soon:
            return HeroColors(background: DesignTokens.Hero.soon, foreground: DesignTokens.Hero.foregroundOnColor, badge: DesignTokens.Hero.badgeOnColor)
        case .now:
            return HeroColors(background: DesignTokens.Hero.now, foreground: DesignTokens.Hero.foregroundOnColor, badge: DesignTokens.Hero.badgeOnNow)
        case .missed:
            return HeroColors(background: DesignTokens.Hero.missed, foreground: DesignTokens.Hero.foregroundOnMissed, badge: DesignTokens.Hero.badgeOnMissed)
        }
    }

    /// 미세먼지 등급 색. 야간에는 강조색 하나로 통일한다.
    func airQualityColor(for level: AirQualityLevel) -> Color {
        guard theme == .day else { return accent }
        switch level {
        case .good: return DesignTokens.AirQuality.good
        case .moderate: return DesignTokens.AirQuality.moderate
        case .bad: return DesignTokens.AirQuality.bad
        case .veryBad: return DesignTokens.AirQuality.veryBad
        case .unavailable: return dim
        }
    }
}

extension EnvironmentValues {
    /// 스탠드 화면 하위 View가 쓰는 색 묶음
    @Entry var standPalette: StandPalette = .day
    /// 시안 대비 배율. 스탠드 화면 하위 View는 시안 값에 이 값을 곱한다.
    @Entry var standScale: CGFloat = 1
}
