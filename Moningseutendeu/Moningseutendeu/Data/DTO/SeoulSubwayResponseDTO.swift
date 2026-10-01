import Foundation

/// 서울 지하철 실시간 도착 응답 (JSON).
/// 정상이면 `errorMessage`와 `realtimeArrivalList`가 오고, 데이터 없음·오류면 최상위에 `code`, `message`만 온다.
nonisolated struct SeoulSubwayResponseDTO: Decodable, Sendable {
    let errorMessage: Status?
    let realtimeArrivalList: [SeoulSubwayArrivalDTO]?
    let code: String?
    let message: String?

    nonisolated struct Status: Decodable, Sendable {
        let code: String?
        let message: String?
    }

    var resultCode: String? { errorMessage?.code ?? code }
}

nonisolated struct SeoulSubwayArrivalDTO: Decodable, Sendable, Equatable {
    let subwayId: String?
    let updnLine: String?
    let trainLineNm: String?
    let statnNm: String?
    /// 도착까지 남은 초. 0으로 오는 경우가 많다
    let barvlDt: String?
    /// 데이터 생성 시각 (KST, "yyyy-MM-dd HH:mm:ss")
    let recptnDt: String?
    let arvlMsg2: String?
    let arvlMsg3: String?
    /// 0 진입, 1 도착, 2 출발, 3 전역출발, 4 전역진입, 5 전역도착, 99 운행중
    let arvlCd: String?
    /// 상하행(1) + 순번(1) + ... 
    let ordkey: String?
    let bstatnNm: String?

    enum CodingKeys: String, CodingKey {
        case subwayId, updnLine, trainLineNm, statnNm, barvlDt, recptnDt, arvlMsg2, arvlMsg3, arvlCd, ordkey, bstatnNm
    }

    init(subwayId: String?, updnLine: String?, trainLineNm: String?, statnNm: String?, barvlDt: String?, recptnDt: String?, arvlMsg2: String?, arvlMsg3: String?, arvlCd: String?, ordkey: String?, bstatnNm: String?) {
        self.subwayId = subwayId
        self.updnLine = updnLine
        self.trainLineNm = trainLineNm
        self.statnNm = statnNm
        self.barvlDt = barvlDt
        self.recptnDt = recptnDt
        self.arvlMsg2 = arvlMsg2
        self.arvlMsg3 = arvlMsg3
        self.arvlCd = arvlCd
        self.ordkey = ordkey
        self.bstatnNm = bstatnNm
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        subwayId = container.flexibleString(forKey: .subwayId)
        updnLine = container.flexibleString(forKey: .updnLine)
        trainLineNm = container.flexibleString(forKey: .trainLineNm)
        statnNm = container.flexibleString(forKey: .statnNm)
        barvlDt = container.flexibleString(forKey: .barvlDt)
        recptnDt = container.flexibleString(forKey: .recptnDt)
        arvlMsg2 = container.flexibleString(forKey: .arvlMsg2)
        arvlMsg3 = container.flexibleString(forKey: .arvlMsg3)
        arvlCd = container.flexibleString(forKey: .arvlCd)
        ordkey = container.flexibleString(forKey: .ordkey)
        bstatnNm = container.flexibleString(forKey: .bstatnNm)
    }
}
