import Foundation

/// 같은 필드가 응답마다 문자열·숫자·null로 섞여 오는 경우를 문자열로 받는다.
/// (예: 경기 버스 `routeName`이 `7000`과 `"1112(예약)"`로 섞여 옴)
nonisolated struct FlexibleString: Decodable, Sendable, Equatable {
    let value: String?

    init(_ value: String?) {
        self.value = value
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = String(int)
        } else if let double = try? container.decode(Double.self) {
            value = String(double)
        } else if let bool = try? container.decode(Bool.self) {
            value = String(bool)
        } else {
            value = nil
        }
    }
}

extension KeyedDecodingContainer {
    /// 키가 없거나 null이면 `nil`, 있으면 문자열로 받는다
    nonisolated func flexibleString(forKey key: Key) -> String? {
        (try? decodeIfPresent(FlexibleString.self, forKey: key))?.flatMap(\.value)
    }
}
