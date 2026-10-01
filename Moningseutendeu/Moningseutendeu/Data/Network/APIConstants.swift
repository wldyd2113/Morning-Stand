import Foundation

/// 엔드포인트 경로와 쿼리 키. 서버 주소(Base URL)는 Config/Secrets.xcconfig에 있다 (git 추적 안 함).
nonisolated enum APIConstants {
    enum DataGoKr {
        static let serviceKey = "serviceKey"
    }

    /// 기상청 단기예보 (VilageFcstInfoService_2.0)
    enum KMA {
        static let ultraShortNowcastPath = "getUltraSrtNcst"
        static let villageForecastPath = "getVilageFcst"
        static let pageNo = "pageNo"
        static let numOfRows = "numOfRows"
        static let dataType = "dataType"
        static let dataTypeJSON = "JSON"
        static let baseDate = "base_date"
        static let baseTime = "base_time"
        static let nx = "nx"
        static let ny = "ny"
        static let successCode = "00"
        static let noDataCode = "03"
        static let quotaExceededCode = "22"
        static let unregisteredKeyCodes: Set<String> = ["30", "31", "32"]

        enum Category {
            static let temperatureNow = "T1H"
            static let temperatureHourly = "TMP"
            static let dailyMax = "TMX"
            static let dailyMin = "TMN"
            static let sky = "SKY"
            static let precipitationType = "PTY"
            static let precipitationProbability = "POP"
        }
    }

    /// 에어코리아 대기오염정보 (ArpltnInforInqireSvc)
    enum AirKorea {
        static let stationMeasurementPath = ["ArpltnInforInqireSvc", "getMsrstnAcctoRltmMesureDnsty"]
        static let sidoMeasurementPath = ["ArpltnInforInqireSvc", "getCtprvnRltmMesureDnsty"]
        static let returnType = "returnType"
        static let returnTypeJSON = "json"
        static let numOfRows = "numOfRows"
        static let pageNo = "pageNo"
        static let stationName = "stationName"
        static let sidoName = "sidoName"
        static let dataTerm = "dataTerm"
        static let dataTermDaily = "DAILY"
        static let version = "ver"
        static let versionValue = "1.3"
        static let sidoPageSize = 100
        static let successCode = "00"
        static let missingValue = "-"
    }

    /// 서울 버스. 정류소정보조회 서비스(stationinfo) 활용 승인이 필요하다.
    enum SeoulBus {
        static let stationByNamePath = ["stationinfo", "getStationByName"]
        static let arrivalsByStopPath = ["stationinfo", "getStationByUid"]
        static let stationQuery = "stSrch"
        static let arsId = "arsId"
        static let resultType = "resultType"
        static let resultTypeJSON = "json"
        /// 도착정보조회(arrive) 서비스. 호출 경로에는 문서 기능명 끝의 `List`가 붙지 않는다
        static let arrivalByRoutePath = ["arrive", "getArrInfoByRoute"]
        static let arrivalByRouteAllPath = ["arrive", "getArrInfoByRouteAll"]
        static let routeID = "busRouteId"
        static let stationID = "stId"
        static let stationOrder = "ord"
        /// 오류 코드 (활용가이드): 0 정상, 1 시스템 오류, 2 잘못된 쿼리, 3 정류소 없음, 4 노선 없음,
        /// 5 잘못된 위치, 6 실시간 정보 없음(잠시 후 재시도), 7 결과 없음, 8 운행 종료
        static let successCode = "0"
        static let emptyResultCodes: Set<String> = ["3", "4", "7", "8"]
        static let temporaryFailureCodes: Set<String> = ["1", "6"]
        static let soonMessage = "곧 도착"
        static let endedMessage = "운행종료"
        static let waitingMessage = "출발대기"
    }

    /// 서울 지하철 실시간 도착. 키가 경로에 들어간다.
    enum SeoulSubway {
        static let responseType = "json"
        static let service = "realtimeStationArrival"
        static let startIndex = "0"
        static let successCode = "INFO-000"
        static let noDataCode = "INFO-200"
        static let invalidKeyCode = "INFO-100"
        static let stationSuffix = "역"
        static let lineDirectionSeparator = " - "
        static let arrivalCodes: Set<String> = ["0", "1"]
        static let departedCode = "2"

        /// subwayId → 노선 이름 (명세서 기준)
        static let lineNames: [String: String] = [
            "1001": "1호선", "1002": "2호선", "1003": "3호선", "1004": "4호선", "1005": "5호선",
            "1006": "6호선", "1007": "7호선", "1008": "8호선", "1009": "9호선",
            "1061": "중앙선", "1063": "경의중앙선", "1065": "공항철도", "1067": "경춘선",
            "1075": "수인분당선", "1077": "신분당선", "1092": "우이신설선", "1093": "서해선",
            "1081": "경강선", "1032": "GTX-A",
        ]
    }
}
