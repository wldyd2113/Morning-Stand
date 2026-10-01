import Foundation

extension Calendar {
    /// 한국 시간(KST)·한국어 로케일 그레고리력. 시각 계산과 표시에 이것만 쓴다.
    nonisolated static var seoul: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: AppConstants.Region.localeIdentifier)
        calendar.timeZone = TimeZone(identifier: AppConstants.Region.timeZoneIdentifier) ?? .current
        return calendar
    }
}
