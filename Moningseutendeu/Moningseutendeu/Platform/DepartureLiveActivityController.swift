import ActivityKit
import Foundation
import OSLog

/// 출발 카운트다운 Live Activity를 하나만 유지한다.
/// - 서버 푸시가 없으므로 앱이 포그라운드일 때 갱신하고, 화면은 절대 시각으로 스스로 줄어든다.
/// - 같은 노선이면 갱신, 노선이 바뀌거나 남아 있는 중복은 끝낸다.
final class DepartureLiveActivityController: LiveActivityControlling {
    private let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: AppConstants.Logging.liveActivityCategory)

    /// `Activity`가 Sendable이 아니라서 MainActor를 벗어나(nonisolated) 한 흐름 안에서만 다룬다.
    nonisolated func sync(_ content: LiveActivityContent?) async {
        let activities = Activity<DepartureActivityAttributes>.activities
        guard let content else {
            for activity in activities { await activity.end(nil, dismissalPolicy: .immediate) }
            return
        }

        let attributes = DepartureActivityAttributes(
            routeTitle: content.routeTitle,
            stopName: content.stopName,
            walkMinutes: content.walkMinutes,
            vehicleText: content.vehicleText
        )
        let state = DepartureActivityAttributes.ContentState(
            updatedAt: content.updatedAt,
            departAt: content.departAt,
            arrivalAt: content.arrivalAt,
            isNextVehicle: content.isNextVehicle,
            urgency: content.urgency
        )
        // 출발 시각이 지나도록 갱신이 없으면 시스템이 "오래된 정보"로 표시한다
        let activityContent = ActivityContent(state: state, staleDate: content.arrivalAt.addingTimeInterval(PolicyConstants.LiveActivity.staleAfterArrivalSeconds))

        let matching = activities.first { $0.attributes.routeTitle == attributes.routeTitle && $0.attributes.stopName == attributes.stopName }
        for activity in activities where activity.id != matching?.id {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        if let matching {
            await matching.update(activityContent)
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            _ = try Activity.request(attributes: attributes, content: activityContent, pushType: nil)
        } catch {
            logger.error("Live Activity 시작 실패: \(error.localizedDescription, privacy: .public)")
        }
    }
}
