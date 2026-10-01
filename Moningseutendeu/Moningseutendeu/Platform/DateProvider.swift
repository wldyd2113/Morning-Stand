import Foundation

/// "현재 시각" 공급자. 테스트와 Preview에서 시각을 고정하려고 주입한다.
nonisolated protocol DateProvider: Sendable {
    var now: Date { get }
}
