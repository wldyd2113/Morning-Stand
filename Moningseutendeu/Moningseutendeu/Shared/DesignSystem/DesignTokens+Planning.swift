import SwiftUI

extension DesignTokens {
    /// 펼침 플래닝 화면.
    enum Planning {
        /// 이 너비 이상이면 사이드바 + 상세 2단, 아니면 1단
        static let splitMinimumWidth: CGFloat = 860
        static let sidebarWidth: CGFloat = 340
        static let sidebarPadding = EdgeInsets(top: 22, leading: 20, bottom: 22, trailing: 20)
        static let detailPadding = EdgeInsets(top: 30, leading: 40, bottom: 28, trailing: 40)
        static let compactDetailPadding = EdgeInsets(top: 20, leading: 20, bottom: 28, trailing: 20)
        static let routeRowPadding = EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        static let optionPadding = EdgeInsets(top: 18, leading: 24, bottom: 18, trailing: 24)
        static let tagPadding = EdgeInsets(top: 3, leading: 9, bottom: 3, trailing: 9)
        static let valueChipPadding = EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12)
        static let compactRouteCardWidth: CGFloat = 220

        static let totalColumnWidth: CGFloat = 120
        static let segmentBarHeight: CGFloat = 28
        static let segmentCaptionHeight: CGFloat = 16
        static let segmentSpacing: CGFloat = 3
        static let waitStripeWidth: CGFloat = 5
        static let legendSwatch = CGSize(width: 14, height: 8)
        static let dayChipSize: CGFloat = 52
        static let dayDotSize: CGFloat = 5
        static let settingRowHeight: CGFloat = 48

        enum FontSize {
            static let title: CGFloat = 34
            static let subtitle: CGFloat = 17
            static let routeName: CGFloat = 19
            static let routeSchedule: CGFloat = 15
            static let routeBest: CGFloat = 20
            static let total: CGFloat = 56
            static let totalUnit: CGFloat = 22
            static let optionTitle: CGFloat = 18
            static let tag: CGFloat = 13
            static let arrival: CGFloat = 15
            static let caption: CGFloat = 13
            static let sectionTitle: CGFloat = 24
            static let dayChip: CGFloat = 18
            static let row: CGFloat = 17
        }

        enum Tracking {
            static let title: CGFloat = -0.5
            static let total: CGFloat = -2
        }
    }
}
