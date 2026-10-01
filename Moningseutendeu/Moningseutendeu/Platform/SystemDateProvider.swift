import Foundation

/// 기기 시각을 그대로 돌려준다. 앱에서 `Date()`를 부르는 유일한 곳.
nonisolated struct SystemDateProvider: DateProvider {
    var now: Date { Date() }
}
