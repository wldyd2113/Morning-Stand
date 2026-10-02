import SwiftUI

extension DesignTokens {
    /// 커버 화면 한눈 모드. 스탠드 화면 구성 요소를 작은 배율로 다시 쓴다 (시안 기준 값 × 배율).
    enum Glance {
        static let padding = EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18)
        static let sectionSpacing: CGFloat = 14
        static let clockScale: CGFloat = 0.32
        static let weatherScale: CGFloat = 0.5
        static let bannerScale: CGFloat = 0.55
        static let heroScale: CGFloat = 0.62
        static let heroHeight: CGFloat = 236
        static let listScale: CGFloat = 0.6
        /// 다른 노선은 위에서부터 이 줄 수까지만 보여준다
        static let maxOtherRoutes = 2
        static let dateFontSize: CGFloat = 15
    }
}
