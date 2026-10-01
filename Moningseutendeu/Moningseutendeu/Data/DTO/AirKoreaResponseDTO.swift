import Foundation

/// 에어코리아 대기오염정보 응답 (`returnType=json`).
nonisolated struct AirKoreaResponseDTO: Decodable, Sendable {
    let response: Response

    nonisolated struct Response: Decodable, Sendable {
        let header: Header
        let body: Body?
    }

    nonisolated struct Header: Decodable, Sendable {
        let resultCode: String
        let resultMsg: String?
    }

    nonisolated struct Body: Decodable, Sendable {
        let items: [AirKoreaMeasurementDTO]?
    }

    var items: [AirKoreaMeasurementDTO] { response.body?.items ?? [] }
}

/// 측정소 한 곳의 측정값. 값은 문자열이고 `"-"`나 null이면 결측이다.
nonisolated struct AirKoreaMeasurementDTO: Decodable, Sendable, Equatable {
    let stationName: String?
    let dataTime: String?
    let pm10Value: String?
    let pm25Value: String?
    let pm10Grade: String?
    let pm25Grade: String?
    let pm10Grade1h: String?
    let pm25Grade1h: String?

    enum CodingKeys: String, CodingKey {
        case stationName, dataTime, pm10Value, pm25Value, pm10Grade, pm25Grade, pm10Grade1h, pm25Grade1h
    }

    init(stationName: String? = nil, dataTime: String? = nil, pm10Value: String? = nil, pm25Value: String? = nil, pm10Grade: String? = nil, pm25Grade: String? = nil, pm10Grade1h: String? = nil, pm25Grade1h: String? = nil) {
        self.stationName = stationName
        self.dataTime = dataTime
        self.pm10Value = pm10Value
        self.pm25Value = pm25Value
        self.pm10Grade = pm10Grade
        self.pm25Grade = pm25Grade
        self.pm10Grade1h = pm10Grade1h
        self.pm25Grade1h = pm25Grade1h
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stationName = container.flexibleString(forKey: .stationName)
        dataTime = container.flexibleString(forKey: .dataTime)
        pm10Value = container.flexibleString(forKey: .pm10Value)
        pm25Value = container.flexibleString(forKey: .pm25Value)
        pm10Grade = container.flexibleString(forKey: .pm10Grade)
        pm25Grade = container.flexibleString(forKey: .pm25Grade)
        pm10Grade1h = container.flexibleString(forKey: .pm10Grade1h)
        pm25Grade1h = container.flexibleString(forKey: .pm25Grade1h)
    }
}
