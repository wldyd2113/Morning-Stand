import Foundation

/// 사용자가 입력한 이동 방법(`RoutePlan`) → 구간 막대가 있는 `RouteOption`.
/// 순서: 도보(집→정류장) → 대기 → 탑승 → [환승 이동 → 탑승]… → 도보(하차→목적지). 0분 구간은 뺀다.
nonisolated enum RouteOptionBuilder {
    static func option(id: String, plan: RoutePlan) -> RouteOption {
        var segments: [RouteSegment] = []
        func append(_ kind: RouteSegment.Kind, _ minutes: Int, label: String? = nil) {
            guard minutes > 0 else { return }
            segments.append(RouteSegment(kind: kind, minutes: minutes, label: label))
        }
        for (index, leg) in plan.legs.enumerated() {
            append(index == 0 ? .walk : .transfer, leg.accessMinutes)
            if index == 0 { append(.wait, plan.waitMinutes) }
            append(leg.kind == .bus ? .bus : .subway, leg.rideMinutes, label: rideLabel(leg))
        }
        append(.walk, plan.finalWalkMinutes)

        let transfers = max(plan.legs.count - 1, 0)
        return RouteOption(
            id: id,
            title: plan.legs.map(rideLabel).joined(separator: " → "),
            note: transfers == 0 ? String(localized: "환승 없음") : String(localized: "환승 \(transfers)회"),
            segments: segments,
            plan: plan
        )
    }

    /// 버스 "1711" → "1711번", 지하철 "3호선 구파발방면" → "3호선"
    static func rideLabel(_ leg: RouteLeg) -> String {
        switch leg.kind {
        case .bus: String(localized: "\(leg.routeKey)번")
        case .subway: leg.routeKey.split(separator: " ").first.map(String.init) ?? leg.routeKey
        }
    }
}
