import SwiftUI

/// 색·간격·모서리·심볼 등 디자인 값. 값은 claude.ai/design "MorningStand" 시안에서 옮겼다.
/// 화면별 세부 값은 `DesignTokens+Stand.swift`, `+Planning`, `+Settings`에 둔다.
enum DesignTokens {
    // MARK: - 색

    enum Palette {
        static let accent = SharedPalette.accent
        static let accentSoftBackground = Color(hex: 0xF4B04F, opacity: 0.16)
        static let background = Color(hex: 0x000000)
        static let deviceFrame = Color(hex: 0x0A0A0B)

        static let textPrimary = Color(hex: 0xF5F5F7)
        static let textSecondary = Color(hex: 0x98989F)
        static let textTertiary = Color(hex: 0x8E8E93)
        static let textDisabled = Color(hex: 0x636366)
        static let textInactive = Color(hex: 0xC7C7CC)
        static let textOnAccent = Color(hex: 0x000000)
        static let textPreviewBody = Color(hex: 0xD1D1D6)

        /// 사이드바
        static let surfaceSidebar = Color(hex: 0x111113)
        /// 카드
        static let surfaceCard = Color(hex: 0x141416)
        /// 그룹 목록, 검색창
        static let surfaceGrouped = Color(hex: 0x1C1C1E)
        /// 칩, 선택 행
        static let surfaceElevated = Color(hex: 0x2C2C2E)
        /// 버튼, 선택된 세그먼트
        static let surfaceControl = Color(hex: 0x3A3A3C)
        static let surfaceControlSelected = Color(hex: 0x636366)

        static let separatorSidebar = Color(hex: 0x1F1F22)
        static let separatorCard = Color(hex: 0x222225)
        static let separatorGrouped = Color(hex: 0x2C2C2E)
        static let sheetHandle = Color(hex: 0x48484A)
        static let sheetShadow = Color(hex: 0x000000, opacity: 0.5)
        static let liveIndicator = Color(hex: 0x3DD68C)
    }

    enum Hero {
        static let relaxed = SharedPalette.heroRelaxed
        static let soon = SharedPalette.heroSoon
        static let now = SharedPalette.heroNow
        static let missed = SharedPalette.heroMissed
        static let foregroundOnColor = Color(hex: 0x000000)
        static let foregroundOnMissed = Color(hex: 0xF5F5F7)
        static let badgeOnColor = Color(hex: 0x000000, opacity: 0.14)
        static let badgeOnNow = Color(hex: 0x000000, opacity: 0.16)
        static let badgeOnMissed = Color(hex: 0xFFFFFF, opacity: 0.12)
        static let badgeOnEnded = Color(hex: 0xFFFFFF, opacity: 0.1)

        static let nightBackground = Color(hex: 0x1E0605)
        static let nightNowBackground = Color(hex: 0x3A0B08)
        static let nightBadge = Color(hex: 0xD9483B, opacity: 0.16)
    }

    enum AirQuality {
        static let good = SharedPalette.airGood
        static let moderate = SharedPalette.airModerate
        static let bad = SharedPalette.airBad
        static let veryBad = SharedPalette.airVeryBad
    }

    enum Segment {
        static let walk = Color(hex: 0x636366)
        static let waitStripe = Color(hex: 0x636366)
        static let waitGap = Color(hex: 0x2C2C2E)
        /// oklch(0.70 0.13 250)
        static let bus = Color(hex: 0x5AA3EC)
        /// oklch(0.72 0.13 160)
        static let subway = Color(hex: 0x4CBD88)
        static let transfer = Color(hex: 0xD1D1D6)
    }

    // MARK: - 간격·모서리·투명도

    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let s: CGFloat = 8
        static let sm: CGFloat = 10
        static let m: CGFloat = 12
        static let ml: CGFloat = 14
        static let l: CGFloat = 16
        static let lx: CGFloat = 18
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    enum Radius {
        static let xs: CGFloat = 2
        static let s: CGFloat = 6
        static let valueChip: CGFloat = 8
        static let m: CGFloat = 9
        static let control: CGFloat = 12
        static let card: CGFloat = 14
        static let group: CGFloat = 16
        static let large: CGFloat = 20
        static let sheet: CGFloat = 28
    }

    enum Opacity {
        /// 오래된(stale) 값을 흐리게 보여줄 때
        static let stale: Double = 0.4
        /// 꺼진 설정 묶음
        static let disabled: Double = 0.35
        /// 보조 설명 글자
        static let secondaryText: Double = 0.72
        /// 수동 모드 전환 버튼 (번인·시선 방해를 줄이려고 흐리게)
        static let modeToggle: Double = 0.35
    }

    enum Animation {
        static let numberTransition: SwiftUI.Animation = .smooth(duration: 0.35)
        static let selection: SwiftUI.Animation = .snappy(duration: 0.2)
        /// 아래에서 올라오는 시트
        static let sheet: SwiftUI.Animation = .snappy(duration: 0.3)
    }

    // MARK: - SF Symbols

    enum Symbol {
        static let sun = "sun.max.fill"
        static let moon = "moon.stars.fill"
        static let cloudSun = "cloud.sun.fill"
        static let cloudMoon = "cloud.moon.fill"
        static let cloud = "cloud.fill"
        static let rain = "cloud.rain.fill"
        static let snow = "cloud.snow.fill"
        static let umbrella = "umbrella.fill"
        static let wifiOff = "wifi.slash"
        static let staleClock = "clock.arrow.circlepath"
        static let search = "magnifyingglass"
        static let starFilled = "star.fill"
        static let star = "star"
        static let minus = "minus"
        static let plus = "plus"
        static let chevronRight = "chevron.right"
        static let settings = "gearshape"
        static let bell = "bell.badge.fill"
        static let airQuality = "aqi.medium"
        static let route = "point.topleft.down.to.point.bottomright.curvepath"
        static let checkmark = "checkmark"
        static let switchToPlanning = "rectangle.split.2x1"
        static let switchToStand = "rectangle.split.1x2"
        static let appIcon = "sunrise.fill"
    }
}
