import Foundation

/// 분 ↔ 초 변환. Domain 곳곳에 흩어져 있던 `* 60`, `/ 60`을 여기로 모은다.
nonisolated extension TimeInterval {
    static let secondsPerMinute: TimeInterval = 60

    /// `minutes`분을 초로
    static func minutes(_ minutes: Int) -> TimeInterval {
        TimeInterval(minutes) * secondsPerMinute
    }

    /// 초를 분으로 (소수 포함). 반올림 방식은 쓰는 쪽이 정한다
    var inMinutes: Double {
        self / Self.secondsPerMinute
    }
}
