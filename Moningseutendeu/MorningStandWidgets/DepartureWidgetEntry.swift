import Foundation
import WidgetKit

/// 위젯 한 시점의 값. 출발 단계는 앱이 미리 계산해 둔 `Moment`를 그대로 쓴다.
nonisolated struct DepartureWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: DashboardSnapshot?
    let moment: DashboardSnapshot.Moment?

    /// 스냅샷이 오래됐으면 흐리게 보여준다
    var isStale: Bool {
        guard let snapshot else { return false }
        return date.timeIntervalSince(snapshot.generatedAt) > SharedConstants.staleSnapshotSeconds
    }

    /// 이 시점에 차량이 도착하기까지 남은 분
    var minutesUntilArrival: Int? {
        guard let arrivalAt = snapshot?.departure?.arrivalAt else { return nil }
        return max(Int(arrivalAt.timeIntervalSince(date) / 60), 0)
    }

    /// 위젯 갤러리·placeholder용 (시안 3b와 같은 값)
    static var placeholder: DepartureWidgetEntry {
        let now = Date.now
        let snapshot = DashboardSnapshot(
            generatedAt: now,
            departure: .init(
                routeTitle: "1711번", stopName: "연신내역", walkMinutes: 5, vehicleText: "버스",
                arrivalAt: now.addingTimeInterval(12 * 60), nextArrivalAt: now.addingTimeInterval(24 * 60), statusText: nil,
                moments: [.init(date: now, urgency: .soon, minutesUntilDeparture: 7, nextDepartureMinutes: nil)]
            ),
            weather: .init(
                temperatureText: "14°", conditionText: "구름 조금", rangeText: "최고 21° · 최저 12°", symbolName: "cloud.sun.fill",
                pm10Text: "미세 보통", pm25Text: "초미세 나쁨", pm10Level: .moderate, pm25Level: .bad, rainText: "오후 6시부터 비"
            )
        )
        return DepartureWidgetEntry(date: now, snapshot: snapshot, moment: snapshot.departure?.moments.first)
    }
}
