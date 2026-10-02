import Foundation

/// 서울 버스 응답 (`resultType=json`).
/// - Note: 2026-10-01 실제 응답으로 확인했다 (Fixtures/seoul_bus_*.json).
///   `itemList`는 배열, 값은 모두 문자열이고 `traTime`은 초 단위다.
nonisolated struct SeoulBusResponseDTO<Item: Decodable & Sendable>: Decodable, Sendable {
    let headerCode: String?
    let headerMessage: String?
    let items: [Item]

    private enum CodingKeys: String, CodingKey { case msgHeader, msgBody }
    private enum HeaderKeys: String, CodingKey { case headerCd, headerMsg }
    private enum BodyKeys: String, CodingKey { case itemList }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let header = try? container.nestedContainer(keyedBy: HeaderKeys.self, forKey: .msgHeader)
        headerCode = header?.flexibleString(forKey: .headerCd)
        headerMessage = header?.flexibleString(forKey: .headerMsg)
        let body = try? container.nestedContainer(keyedBy: BodyKeys.self, forKey: .msgBody)
        // 결과가 한 건이면 배열이 아니라 객체 하나로 올 수 있다
        if let list = try? body?.decodeIfPresent([Item].self, forKey: .itemList) {
            items = list
        } else if let single = try? body?.decodeIfPresent(Item.self, forKey: .itemList) {
            items = [single]
        } else {
            items = []
        }
    }
}

/// 정류소 이름 검색 결과. `tmX`/`tmY`는 이름과 달리 WGS84 경도/위도다.
nonisolated struct SeoulBusStationDTO: Decodable, Sendable, Equatable {
    let arsId: String?
    let stNm: String?
    let tmX: String?
    let tmY: String?

    enum CodingKeys: String, CodingKey { case arsId, stNm, tmX, tmY }

    init(arsId: String?, stNm: String?, tmX: String?, tmY: String?) {
        self.arsId = arsId
        self.stNm = stNm
        self.tmX = tmX
        self.tmY = tmY
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        arsId = container.flexibleString(forKey: .arsId)
        stNm = container.flexibleString(forKey: .stNm)
        tmX = container.flexibleString(forKey: .tmX)
        tmY = container.flexibleString(forKey: .tmY)
    }
}

/// 좌표 기반 주변 정류소 (`getStationByPos`).
/// - Note: 2026-10-02 실제 응답으로 확인했다 (Fixtures/seoul_bus_station_by_pos_normal.json).
///   이름 검색과 달리 이름이 `stationNm`, 좌표가 `gpsX`(경도)/`gpsY`(위도), 거리가 `dist`(m, 문자열)다.
///   미정차 정류소는 `arsId`가 `"0"`으로 온다.
nonisolated struct SeoulBusNearbyStationDTO: Decodable, Sendable, Equatable {
    let arsId: String?
    let stationNm: String?
    let gpsX: String?
    let gpsY: String?
    let dist: String?

    enum CodingKeys: String, CodingKey { case arsId, stationNm, gpsX, gpsY, dist }

    init(arsId: String?, stationNm: String?, gpsX: String?, gpsY: String?, dist: String?) {
        self.arsId = arsId
        self.stationNm = stationNm
        self.gpsX = gpsX
        self.gpsY = gpsY
        self.dist = dist
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        arsId = container.flexibleString(forKey: .arsId)
        stationNm = container.flexibleString(forKey: .stationNm)
        gpsX = container.flexibleString(forKey: .gpsX)
        gpsY = container.flexibleString(forKey: .gpsY)
        dist = container.flexibleString(forKey: .dist)
    }
}

/// 정류소별 노선 도착 정보.
nonisolated struct SeoulBusArrivalDTO: Decodable, Sendable, Equatable {
    let rtNm: String?
    let stNm: String?
    let adirection: String?
    let nxtStn: String?
    let arrmsg1: String?
    let arrmsg2: String?
    /// 첫 번째 차량 도착 예정 초
    let traTime1: String?
    let traTime2: String?
    let gpsX: String?
    let gpsY: String?

    enum CodingKeys: String, CodingKey { case rtNm, stNm, adirection, nxtStn, arrmsg1, arrmsg2, traTime1, traTime2, gpsX, gpsY }

    init(rtNm: String?, stNm: String? = nil, adirection: String? = nil, nxtStn: String? = nil, arrmsg1: String?, arrmsg2: String?, traTime1: String? = nil, traTime2: String? = nil, gpsX: String? = nil, gpsY: String? = nil) {
        self.rtNm = rtNm
        self.stNm = stNm
        self.adirection = adirection
        self.nxtStn = nxtStn
        self.arrmsg1 = arrmsg1
        self.arrmsg2 = arrmsg2
        self.traTime1 = traTime1
        self.traTime2 = traTime2
        self.gpsX = gpsX
        self.gpsY = gpsY
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rtNm = container.flexibleString(forKey: .rtNm)
        stNm = container.flexibleString(forKey: .stNm)
        adirection = container.flexibleString(forKey: .adirection)
        nxtStn = container.flexibleString(forKey: .nxtStn)
        arrmsg1 = container.flexibleString(forKey: .arrmsg1)
        arrmsg2 = container.flexibleString(forKey: .arrmsg2)
        traTime1 = container.flexibleString(forKey: .traTime1)
        traTime2 = container.flexibleString(forKey: .traTime2)
        gpsX = container.flexibleString(forKey: .gpsX)
        gpsY = container.flexibleString(forKey: .gpsY)
    }
}
