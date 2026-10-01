import SwiftUI

extension EdgeInsets {
    /// 모든 여백에 같은 배율을 곱한다. 스탠드 화면에서 시안 값을 화면 크기에 맞출 때 쓴다.
    func scaled(_ scale: CGFloat) -> EdgeInsets {
        EdgeInsets(top: top * scale, leading: leading * scale, bottom: bottom * scale, trailing: trailing * scale)
    }
}
