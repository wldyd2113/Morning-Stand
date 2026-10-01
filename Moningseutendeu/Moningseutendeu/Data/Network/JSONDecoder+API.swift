import Foundation

extension JSONDecoder {
    /// API 응답 디코딩. 실패하면 `AppError.decoding`으로 바꾼다.
    nonisolated static func decodeAPI<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw AppError.decoding
        }
    }
}
