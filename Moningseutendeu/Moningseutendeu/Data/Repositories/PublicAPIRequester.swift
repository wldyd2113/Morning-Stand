import Foundation

/// API별 요청 조립과 본문 에러 코드 확인. 각 Repository가 공유한다.
nonisolated struct PublicAPIRequester: Sendable {
    let apiClient: any APIClient
    let configuration: ServerConfiguration

    // MARK: - 기상청

    func kmaItems(path: String, base: KMABaseTime, grid: GridPoint, pageSize: Int) async throws -> [KMAItemDTO] {
        guard let baseURL = configuration.kmaBaseURL, !configuration.dataGoKrServiceKey.isEmpty else { throw AppError.apiKeyInvalid }
        typealias Keys = APIConstants.KMA
        let endpoint = Endpoint(
            api: .kma,
            baseURL: baseURL,
            pathComponents: [path],
            query: [
                APIConstants.DataGoKr.serviceKey: configuration.dataGoKrServiceKey,
                Keys.pageNo: "1",
                Keys.numOfRows: "\(pageSize)",
                Keys.dataType: Keys.dataTypeJSON,
                Keys.baseDate: base.date,
                Keys.baseTime: base.time,
                Keys.nx: "\(grid.nx)",
                Keys.ny: "\(grid.ny)",
            ],
            secrets: configuration.secrets
        )
        let data = try await apiClient.data(for: endpoint)
        if let error = DataGoKrErrorDTO.error(in: data) { throw error }
        let dto = try JSONDecoder.decodeAPI(KMAResponseDTO.self, from: data)
        switch dto.response.header.resultCode {
        case Keys.successCode: return dto.items
        case Keys.noDataCode: return []
        case Keys.quotaExceededCode: throw AppError.quotaExceeded
        case let code where Keys.unregisteredKeyCodes.contains(code): throw AppError.apiKeyInvalid
        case let code: throw AppError.server(code: code)
        }
    }

    // MARK: - 에어코리아

    func airMeasurements(path: [String], query: [String: String]) async throws -> [AirKoreaMeasurementDTO] {
        guard let baseURL = configuration.airKoreaBaseURL, !configuration.dataGoKrServiceKey.isEmpty else { throw AppError.apiKeyInvalid }
        typealias Keys = APIConstants.AirKorea
        var fullQuery = query
        fullQuery[APIConstants.DataGoKr.serviceKey] = configuration.dataGoKrServiceKey
        fullQuery[Keys.returnType] = Keys.returnTypeJSON
        fullQuery[Keys.pageNo] = "1"
        fullQuery[Keys.version] = Keys.versionValue
        let endpoint = Endpoint(api: .airKorea, baseURL: baseURL, pathComponents: path, query: fullQuery, secrets: configuration.secrets)
        let data = try await apiClient.data(for: endpoint)
        if let error = DataGoKrErrorDTO.error(in: data) { throw error }
        let dto = try JSONDecoder.decodeAPI(AirKoreaResponseDTO.self, from: data)
        guard dto.response.header.resultCode == Keys.successCode else {
            throw AppError.server(code: dto.response.header.resultCode)
        }
        return dto.items
    }

    // MARK: - 서울 지하철

    func subwayArrivals(stationName: String) async throws -> [SeoulSubwayArrivalDTO] {
        guard let baseURL = configuration.seoulSubwayBaseURL, !configuration.seoulSubwayKey.isEmpty else { throw AppError.apiKeyInvalid }
        typealias Keys = APIConstants.SeoulSubway
        let endpoint = Endpoint(
            api: .seoulSubway,
            baseURL: baseURL,
            pathComponents: [configuration.seoulSubwayKey, Keys.responseType, Keys.service, Keys.startIndex, "\(PolicyConstants.Subway.pageSize)", stationName],
            query: [:],
            secrets: configuration.secrets
        )
        let data = try await apiClient.data(for: endpoint)
        let dto = try JSONDecoder.decodeAPI(SeoulSubwayResponseDTO.self, from: data)
        switch dto.resultCode {
        case Keys.successCode: return dto.realtimeArrivalList ?? []
        case Keys.noDataCode: return []
        case Keys.invalidKeyCode: throw AppError.apiKeyInvalid
        case let code: throw AppError.server(code: code ?? "")
        }
    }

    // MARK: - 서울 버스

    func seoulBus<Item: Decodable & Sendable>(path: [String], query: [String: String], as type: Item.Type) async throws -> [Item] {
        guard let baseURL = configuration.seoulBusBaseURL, !configuration.dataGoKrServiceKey.isEmpty else { throw AppError.apiKeyInvalid }
        typealias Keys = APIConstants.SeoulBus
        var fullQuery = query
        fullQuery[APIConstants.DataGoKr.serviceKey] = configuration.dataGoKrServiceKey
        fullQuery[Keys.resultType] = Keys.resultTypeJSON
        let endpoint = Endpoint(api: .seoulBus, baseURL: baseURL, pathComponents: path, query: fullQuery, secrets: configuration.secrets)
        let data = try await apiClient.data(for: endpoint)
        if let error = DataGoKrErrorDTO.error(in: data) { throw error }
        let dto = try JSONDecoder.decodeAPI(SeoulBusResponseDTO<Item>.self, from: data)
        // 등록되지 않은 키는 HTTP 401로 오고 APIClient가 `.apiKeyInvalid`로 바꾼다
        switch dto.headerCode {
        case Keys.successCode, nil: return dto.items
        case let code? where Keys.emptyResultCodes.contains(code): return []
        // 일시 오류는 5xx처럼 다뤄 한 번 다시 시도하게 한다
        case let code? where Keys.temporaryFailureCodes.contains(code): throw AppError.server(code: "5\(code)")
        case let code?: throw AppError.server(code: code)
        }
    }
}
