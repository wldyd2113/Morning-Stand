import SwiftUI

extension DesignTokens {
    /// 반접힘 스탠드 화면. 시안(패널 960×420pt 두 장 + 힌지 36pt) 기준 값이며,
    /// 실제 화면에서는 `StandView`가 계산한 배율(scale)을 곱해서 쓴다.
    enum Stand {
        /// 시안의 스탠드 화면 전체 크기 (위 패널 + 힌지 + 아래 패널)
        static let referenceSize = CGSize(width: 960, height: 876)
        /// 힌지 위아래로 비워 두는 높이. 숫자가 접히는 부분에 걸치지 않게 한다.
        static let hingeGap: CGFloat = 36
        static let hingeLineHeight: CGFloat = 2
        static let hingeLine = Color(hex: 0x1C1C1E)

        static let topPanelPadding = EdgeInsets(top: 40, leading: 48, bottom: 36, trailing: 48)
        static let bottomPanelPadding = EdgeInsets(top: 28, leading: 28, bottom: 26, trailing: 40)
        static let topColumnSpacing: CGFloat = 24
        static let topRowSpacing: CGFloat = 22
        static let bottomColumnSpacing: CGFloat = 36
        static let weatherColumnWidth: CGFloat = 380
        static let heroWidth: CGFloat = 560

        enum FontSize {
            static let clock: CGFloat = 212
            static let date: CGFloat = 30
            static let temperature: CGFloat = 112
            static let condition: CGFloat = 26
            static let temperatureRange: CGFloat = 24
            static let airQualityChip: CGFloat = 20
            static let banner: CGFloat = 28
            static let bannerBadge: CGFloat = 22
            static let bannerMessage: CGFloat = 23
            static let heroBadge: CGFloat = 24
            static let heroNumber: CGFloat = 232
            static let heroWord: CGFloat = 136
            static let heroUnit: CGFloat = 48
            static let heroRoute: CGFloat = 34
            static let heroDetail: CGFloat = 23
            static let noticeHeadline: CGFloat = 108
            static let noticeTitle: CGFloat = 26
            static let sectionTitle: CGFloat = 20
            static let rowTitle: CGFloat = 34
            static let rowSubtitle: CGFloat = 17
            static let footer: CGFloat = 18
        }

        enum Tracking {
            static let clock: CGFloat = -8
            static let temperature: CGFloat = -4
            static let heroHeadline: CGFloat = -6
            static let noticeHeadline: CGFloat = -4
            static let heroUnit: CGFloat = -1
        }

        /// 글자 크기 대비 줄 높이. 큰 숫자는 시안처럼 위아래 여백을 줄인다.
        enum LineHeight {
            static let clock: CGFloat = 0.84
            static let temperature: CGFloat = 0.9
            static let heroHeadline: CGFloat = 0.8
            static let noticeHeadline: CGFloat = 0.9
            static let heroUnit: CGFloat = 1.05
        }

        enum Size {
            static let weatherSymbol: CGFloat = 64
            static let airQualityDot: CGFloat = 12
            static let footerDot: CGFloat = 8
            static let bannerIcon: CGFloat = 24
            static let modeToggle: CGFloat = 44
            static let noticeBorder: CGFloat = 2
            static let rowSeparator: CGFloat = 1
        }

        enum Radius {
            static let hero: CGFloat = 32
            static let banner: CGFloat = 20
            static let skeletonRow: CGFloat = 16
            static let skeletonText: CGFloat = 10
            static let skeletonBlock: CGFloat = 24
        }

        enum Padding {
            static let hero = EdgeInsets(top: 26, leading: 32, bottom: 28, trailing: 32)
            static let rainBanner = EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
            static let noticeBanner = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
            static let badge = EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
            static let chip = EdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
            static let rowVertical: CGFloat = 14
            static let sectionTitle = EdgeInsets(top: 6, leading: 0, bottom: 10, trailing: 0)
        }

        enum Spacing {
            static let dateTop: CGFloat = 22
            static let weatherSymbolToTemperature: CGFloat = 16
            static let conditionTop: CGFloat = 8
            static let rangeTop: CGFloat = 4
            static let chipsTop: CGFloat = 14
            static let chips: CGFloat = 10
            static let chipContent: CGFloat = 8
            static let banner: CGFloat = 16
            static let noticeBanner: CGFloat = 18
            static let heroHeadlineToUnit: CGFloat = 16
            static let heroFooter: CGFloat = 4
            static let rowText: CGFloat = 2
            static let footerContent: CGFloat = 8
            static let skeleton: CGFloat = 14
        }

        /// 로딩 스켈레톤 크기 (시안 그대로)
        enum Skeleton {
            static let temperature = CGSize(width: 230, height: 100)
            static let conditionLine = CGSize(width: 180, height: 28)
            static let rangeLine = CGSize(width: 250, height: 28)
            static let chips = CGSize(width: 300, height: 40)
            static let bannerHeight: CGFloat = 62
            static let heroBadge = CGSize(width: 110, height: 36)
            static let heroNumber = CGSize(width: 320, height: 150)
            static let heroRoute = CGSize(width: 130, height: 34)
            static let heroDetail = CGSize(width: 400, height: 24)
            static let rowHeight: CGFloat = 72
            static let rowCount = 3
        }
    }
}
