import Foundation

/// Live Activity에 보여줄 값. ActivityKit을 모르는 ViewModel이 만든다.
nonisolated struct LiveActivityContent: Sendable, Equatable {
    var routeTitle: String
    var stopName: String
    var walkMinutes: Int
    var vehicleText: String
    var updatedAt: Date
    /// 보여주는 차량(이번 차, 놓쳤으면 다음 차) 기준 출발·도착 시각
    var departAt: Date
    var arrivalAt: Date
    var isNextVehicle: Bool
    var urgency: DepartureUrgencyLevel
}

/// Live Activity 시작·갱신·종료. `nil`을 넘기면 진행 중인 Live Activity를 끝낸다.
protocol LiveActivityControlling {
    func sync(_ content: LiveActivityContent?) async
}

/// Preview·테스트용. 아무것도 하지 않는다.
struct NoopLiveActivityController: LiveActivityControlling {
    func sync(_ content: LiveActivityContent?) async {}
}
