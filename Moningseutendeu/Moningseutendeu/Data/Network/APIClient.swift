import Foundation

/// 네트워크 호출 추상화. Repository는 이 프로토콜만 알고, 테스트에서는 fixture를 돌려주는 Mock을 쓴다.
/// HTTP 상태 오류는 여기서 `AppError`로 바꾸고, 200 안의 본문 에러 코드는 각 Repository가 확인한다.
nonisolated protocol APIClient: Sendable {
    func data(for endpoint: Endpoint) async throws -> Data
}
