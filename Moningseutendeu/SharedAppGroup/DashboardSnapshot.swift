import Foundation

/// 앱이 App Group에 써 두고 위젯이 읽는 최신 대시보드. 위젯은 네트워크를 쓰지 않고 이것만 읽는다.
/// 남은 분이 아니라 절대 시각과 "분 단위 미리 계산한 단계"를 넣어서, 위젯이 시간이 지나도 맞게 보여준다.
nonisolated struct DashboardSnapshot: Codable, Sendable, Equatable {
    static let currentSchemaVersion = 1

    var schemaVersion = DashboardSnapshot.currentSchemaVersion
    var generatedAt: Date
    var departure: Departure?
    var weather: Weather?

    nonisolated struct Departure: Codable, Sendable, Equatable {
        /// "1711번", "3호선 구파발방면"
        var routeTitle: String
        var stopName: String
        var walkMinutes: Int
        /// "버스", "열차"
        var vehicleText: String
        var arrivalAt: Date?
        var nextArrivalAt: Date?
        /// 남은 시간 대신 보여줄 상태 ("운행 종료", "출발대기")
        var statusText: String?
        /// 1분 간격으로 미리 계산한 출발 단계
        var moments: [Moment]

        var departAt: Date? { arrivalAt.map { $0.addingTimeInterval(-TimeInterval(walkMinutes * 60)) } }

        /// `date` 시점에 보여줄 단계 (그 시각 이전의 마지막 값)
        func moment(at date: Date) -> Moment? {
            moments.last { $0.date <= date } ?? moments.first
        }
    }

    nonisolated struct Moment: Codable, Sendable, Equatable {
        var date: Date
        var urgency: DepartureUrgencyLevel
        /// 출발까지 남은 분 (놓쳤으면 음수)
        var minutesUntilDeparture: Int
        /// 놓쳤을 때 다음 차 기준 출발까지 남은 분
        var nextDepartureMinutes: Int?
    }

    nonisolated struct Weather: Codable, Sendable, Equatable {
        var temperatureText: String
        var conditionText: String
        var rangeText: String
        var symbolName: String
        var pm10Text: String
        var pm25Text: String
        var pm10Level: AirLevel
        var pm25Level: AirLevel
        /// "18시부터 비"
        var rainText: String?
    }

    nonisolated enum AirLevel: String, Codable, Sendable {
        case good, moderate, bad, veryBad, unavailable
    }
}
