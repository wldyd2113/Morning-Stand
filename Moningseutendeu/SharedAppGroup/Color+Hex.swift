import SwiftUI

extension Color {
    /// `0xRRGGBB` 값으로 색을 만든다. 디자인 시안의 hex 값을 그대로 옮기기 위한 용도.
    init(hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
