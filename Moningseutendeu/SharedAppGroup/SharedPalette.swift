import SwiftUI

/// 앱과 위젯이 같이 쓰는 색. 앱의 DesignTokens도 이 값을 참조한다.
enum SharedPalette {
    static let accent = Color(hex: 0xF4B04F)
    static let textPrimary = Color(hex: 0xF5F5F7)
    static let textSecondary = Color(hex: 0x98989F)
    static let textOnColor = Color(hex: 0x000000)
    static let widgetBackground = Color(hex: 0x1C1C1E)
    static let divider = Color(hex: 0x2C2C2E)
    static let trackBackground = Color(hex: 0x48484A)
    static let islandBackground = Color(hex: 0x000000)

    static let heroRelaxed = Color(hex: 0x3DD68C)
    static let heroSoon = Color(hex: 0xFFD23F)
    static let heroNow = Color(hex: 0xFF5A4E)
    static let heroMissed = Color(hex: 0x3A3A3E)

    static let airGood = Color(hex: 0x4DA3FF)
    static let airModerate = Color(hex: 0x3DD68C)
    static let airBad = Color(hex: 0xFF9F2E)
    static let airVeryBad = Color(hex: 0xFF5A4E)
    static let airUnavailable = Color(hex: 0x636366)

    /// 단계 색. 위젯·Dynamic Island에서 숫자와 점에 쓴다 (놓침은 회색 대신 보조 글자색)
    static func urgencyColor(_ level: DepartureUrgencyLevel) -> Color {
        switch level {
        case .relaxed: heroRelaxed
        case .soon: heroSoon
        case .now: heroNow
        case .missed: textSecondary
        }
    }

    static func airColor(_ level: DashboardSnapshot.AirLevel) -> Color {
        switch level {
        case .good: airGood
        case .moderate: airModerate
        case .bad: airBad
        case .veryBad: airVeryBad
        case .unavailable: airUnavailable
        }
    }
}
