import SwiftUI

/// 로딩 중 자리를 차지하는 둥근 사각형.
struct SkeletonBlock: View {
    var width: CGFloat?
    var height: CGFloat
    var cornerRadius: CGFloat
    var color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(color)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .accessibilityHidden(true)
    }
}

#Preview {
    SkeletonBlock(width: 200, height: 40, cornerRadius: 10, color: StandPalette.day.skeleton)
        .padding()
        .background(DesignTokens.Palette.background)
}
