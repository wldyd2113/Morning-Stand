import SwiftUI

/// 135° 사선 줄무늬. 경로 막대의 "대기" 구간에 쓴다.
struct StripedFill: View {
    var stripeColor: Color
    var gapColor: Color
    var stripeWidth: CGFloat

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(gapColor))
            let period = stripeWidth * 2
            var path = Path()
            var x = -size.height
            while x < size.width + size.height {
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += period
            }
            context.stroke(path, with: .color(stripeColor), lineWidth: stripeWidth)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    StripedFill(stripeColor: DesignTokens.Segment.waitStripe, gapColor: DesignTokens.Segment.waitGap, stripeWidth: DesignTokens.Planning.waitStripeWidth)
        .frame(width: 120, height: 28)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.s))
        .padding()
}
