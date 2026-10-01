import SwiftUI

extension DesignTokens {
    /// 온보딩·설정 화면.
    enum Settings {
        static let screenPadding: CGFloat = 20
        static let searchFieldHeight: CGFloat = 40
        static let stopRowPadding = EdgeInsets(top: 12, leading: 10, bottom: 12, trailing: 10)
        static let starButtonSize: CGFloat = 44
        static let sheetPadding = EdgeInsets(top: 8, leading: 20, bottom: 30, trailing: 20)
        static let sheetHandle = CGSize(width: 36, height: 5)
        static let sheetShadowRadius: CGFloat = 30
        static let sheetShadowY: CGFloat = -10
        /// 시트를 이만큼(pt) 아래로 끌면 닫는다
        static let sheetDismissDragDistance: CGFloat = 80
        static let stepperButtonSize: CGFloat = 48
        static let stepperPadding: CGFloat = 8
        static let routeChipPadding = EdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14)
        static let routeChipRingWidth: CGFloat = 1.5
        static let primaryButtonHeight: CGFloat = 52
        static let groupRowMinHeight: CGFloat = 48
        static let groupRowHorizontalPadding: CGFloat = 16
        static let previewIconSize: CGFloat = 38
        static let previewIconRadius: CGFloat = 10

        enum FontSize {
            static let title: CGFloat = 28
            static let largeTitle: CGFloat = 34
            static let body: CGFloat = 17
            static let callout: CGFloat = 15
            static let subheadline: CGFloat = 14
            static let footnote: CGFloat = 13
            static let sheetTitle: CGFloat = 22
            static let stepperValue: CGFloat = 36
            static let stepperUnit: CGFloat = 18
            static let stepperSymbol: CGFloat = 22
            static let star: CGFloat = 22
        }
    }
}
