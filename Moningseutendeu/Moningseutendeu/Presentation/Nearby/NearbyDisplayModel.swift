import Foundation

/// 주변 정류장 탭이 그리는 값. 좌표는 Domain `Coordinate`로 넘기고, 지도 타입 변환은 View가 한다.
nonisolated struct NearbyDisplayModel: Sendable, Equatable {
    /// "현재 위치 기준 · 오차 35m"
    var locationText: String?
    var isLocating: Bool
    var pins: [Pin]
    /// 검색 결과가 없거나 실패했을 때 문구
    var message: String?
    /// 위치 권한이 거부돼 설정 앱으로 보내야 하는지
    var showsOpenSettings: Bool
    /// 아직 검색 전일 때 지도 중심 (집 → 기본 좌표)
    var initialCenter: Coordinate
    var userCoordinate: Coordinate?
    var homeCoordinate: Coordinate?
    /// 검색 결과가 바뀔 때마다 늘어난다. View가 이 값이 바뀌면 지도를 핀에 맞춘다
    var searchGeneration: Int
    /// 마지막 검색 결과 요약 "주변 정류장 12곳". 결과가 없으면 `nil`
    var resultSummary: String?
    var home: Home
    var automation: Automation
    var selection: Selection?

    nonisolated struct Pin: Sendable, Equatable, Identifiable {
        var id: String
        var name: String
        var coordinate: Coordinate
        var isSelected: Bool
        var isFavorite: Bool
    }

    nonisolated struct Home: Sendable, Equatable {
        var title: String
        var actionTitle: String
        var isSet: Bool
        var isUpdating: Bool
    }

    nonisolated struct Automation: Sendable, Equatable {
        var isOn: Bool
        /// 집 위치가 있어야 켤 수 있다
        var isAvailable: Bool
        /// 켤 수 없을 때 이유 "먼저 위 카드에서 집 위치를 설정해 주세요"
        var unavailableReason: String?
        var isUpdating: Bool
        var detail: String
        var errorMessage: String?
    }

    nonisolated struct Selection: Sendable, Equatable {
        var name: String
        /// "01902 · 48m"
        var detail: String
        /// "4분" (계산 중이면 직선거리 어림값)
        var walkMinutesText: String
        /// "지도 도보 경로 · 집에서" / "직선거리로 어림한 시간"
        var walkSourceText: String
        var isCalculatingWalk: Bool
        var arrivals: Arrivals
        var actionTitle: String
        var isSaving: Bool
        var errorMessage: String?
    }

    nonisolated enum Arrivals: Sendable, Equatable {
        case loading
        /// `updatedText`: "12초 전 기준"
        case rows([ArrivalRow], updatedText: String, isRefreshing: Bool)
        case message(String)
    }

    nonisolated struct ArrivalRow: Sendable, Equatable, Identifiable {
        var id: String
        /// "1711번"
        var title: String
        /// "불광역 방면"
        var subtitle: String
        /// "3분" / "곧 도착" / "종료"
        var etaText: String
        /// "다음 12분"
        var nextText: String
        /// 도보 시간을 뺀 출발 안내 ("2분 뒤 출발", "지금 출발", "이번 차 놓침 · 다음 차 9분 뒤")
        var departureText: String?
        var urgency: DepartureUrgency?
    }
}
