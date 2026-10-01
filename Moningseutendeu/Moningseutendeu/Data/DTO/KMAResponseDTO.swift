import Foundation

/// 기상청 단기예보 응답 (`dataType=JSON`). 실황·예보 항목을 같은 구조로 받는다.
nonisolated struct KMAResponseDTO: Decodable, Sendable {
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
        let items: Items?
    }

    nonisolated struct Items: Decodable, Sendable {
        let item: [KMAItemDTO]?
    }

    var items: [KMAItemDTO] { response.body?.items?.item ?? [] }
}

/// 실황(`obsrValue`)과 예보(`fcstDate`, `fcstTime`, `fcstValue`) 항목.
nonisolated struct KMAItemDTO: Decodable, Sendable, Equatable {
    let category: String
    let baseDate: String?
    let baseTime: String?
    let obsrValue: String?
    let fcstDate: String?
    let fcstTime: String?
    let fcstValue: String?

    enum CodingKeys: String, CodingKey {
        case category, baseDate, baseTime, obsrValue, fcstDate, fcstTime, fcstValue
    }

    init(category: String, baseDate: String? = nil, baseTime: String? = nil, obsrValue: String? = nil, fcstDate: String? = nil, fcstTime: String? = nil, fcstValue: String? = nil) {
        self.category = category
        self.baseDate = baseDate
        self.baseTime = baseTime
        self.obsrValue = obsrValue
        self.fcstDate = fcstDate
        self.fcstTime = fcstTime
        self.fcstValue = fcstValue
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decode(String.self, forKey: .category)
        baseDate = container.flexibleString(forKey: .baseDate)
        baseTime = container.flexibleString(forKey: .baseTime)
        obsrValue = container.flexibleString(forKey: .obsrValue)
        fcstDate = container.flexibleString(forKey: .fcstDate)
        fcstTime = container.flexibleString(forKey: .fcstTime)
        fcstValue = container.flexibleString(forKey: .fcstValue)
    }
}
