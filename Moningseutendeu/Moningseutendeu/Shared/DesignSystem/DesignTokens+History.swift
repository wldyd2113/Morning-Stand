import SwiftUI

extension DesignTokens {
    /// 출근 기록·통계 탭.
    enum History {
        static let tilePadding = EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        static let tileMinWidth: CGFloat = 150
        static let chartHeight: CGFloat = 200
        static let chartPadding = EdgeInsets(top: 16, leading: 16, bottom: 12, trailing: 16)
        static let barWidth: CGFloat = 22
        static let barCornerRadius: CGFloat = 4
        static let lineWidth: CGFloat = 2
        /// 점 지름. 8pt 이상으로 둔다
        static let pointDiameter: CGFloat = 10
        static let calloutPadding = EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        static let tileValueMinimumScale: CGFloat = 0.6
        /// 출발 시각 차트 x축 눈금 간격(일)
        static let dayAxisStride = 7
        static let rowPadding = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)

        enum FontSize {
            static let tileValue: CGFloat = 28
            static let tileLabel: CGFloat = 13
            static let sectionTitle: CGFloat = 20
            static let row: CGFloat = 16
            static let rowDetail: CGFloat = 13
        }
    }
}
