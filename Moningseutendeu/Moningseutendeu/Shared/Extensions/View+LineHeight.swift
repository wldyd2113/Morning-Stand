import SwiftUI

extension View {
    /// 큰 글자의 줄 높이를 글자 크기 × 배수로 고정한다 (CSS `line-height`와 같은 효과).
    func lineHeight(fontSize: CGFloat, multiple: CGFloat) -> some View {
        frame(height: fontSize * multiple)
    }
}
