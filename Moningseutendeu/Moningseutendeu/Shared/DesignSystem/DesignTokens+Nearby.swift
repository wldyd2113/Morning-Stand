import SwiftUI

extension DesignTokens {
    /// 주변 정류장 탭 (지도 + 정류장 패널).
    enum Nearby {
        static let cardPadding = EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        static let iconSize: CGFloat = 32
        /// 펼친 화면에서 검색 화면 내용이 너무 넓어지지 않게 제한한다
        static let contentMaxWidth: CGFloat = 560
        static let searchIconSize: CGFloat = 56
        static let searchCardPadding = EdgeInsets(top: 24, leading: 20, bottom: 20, trailing: 20)
        /// 도착 정보 시트의 중간 높이 (지도를 가리지 않게)
        static let sheetMediumFraction: CGFloat = 0.45
        static let mapOverlayPadding: CGFloat = 12
        static let pinSize: CGFloat = 30
        static let selectedPinSize: CGFloat = 40
        static let pinRingWidth: CGFloat = 2
        static let homePinSize: CGFloat = 28
        static let messagePadding = EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        static let arrivalRowPadding = EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        static let urgencyDotSize: CGFloat = 8

        enum FontSize {
            static let cardTitle: CGFloat = 17
            static let walkValue: CGFloat = 28
            static let searchTitle: CGFloat = 22
            static let searchSymbol: CGFloat = 24
            static let pinSymbol: CGFloat = 14
            static let selectedPinSymbol: CGFloat = 18
            static let pinLabel: CGFloat = 12
            static let arrivalTitle: CGFloat = 17
            static let arrivalEta: CGFloat = 20
            static let arrivalDetail: CGFloat = 13
        }
    }
}
