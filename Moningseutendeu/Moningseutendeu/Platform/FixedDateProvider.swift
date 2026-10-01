import Foundation

/// 항상 같은 시각을 돌려준다. Preview·테스트·스냅샷용.
nonisolated struct FixedDateProvider: DateProvider {
    let now: Date
}
