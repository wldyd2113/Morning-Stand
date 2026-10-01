import Foundation

/// 화면 섹션 하나의 상태. 섹션마다 따로 가져서 한 API가 실패해도 다른 섹션은 정상 표시한다.
nonisolated enum SectionState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value, fetchedAt: Date)
    case stale(Value, fetchedAt: Date, reason: StaleReason)
    case failed(AppError)

    var value: Value? {
        switch self {
        case .loaded(let value, _), .stale(let value, _, _): value
        case .idle, .loading, .failed: nil
        }
    }

    var fetchedAt: Date? {
        switch self {
        case .loaded(_, let fetchedAt), .stale(_, let fetchedAt, _): fetchedAt
        case .idle, .loading, .failed: nil
        }
    }

    /// 새로 불러오기 시작할 때의 상태. 이전 값이 있으면 그대로 둬서 화면이 깜빡이지 않게 한다.
    func beginningLoad() -> SectionState {
        switch self {
        case .loaded, .stale: self
        case .idle, .loading, .failed: .loading
        }
    }

    /// 불러오기 결과를 반영한 상태.
    /// 실패했더라도 이전 값이 있으면 `.stale`로 이전 값을 계속 보여준다.
    func resolved(with result: Result<Timestamped<Value>, AppError>) -> SectionState {
        switch result {
        case .success(let timestamped):
            switch timestamped.freshness {
            case .live:
                return .loaded(timestamped.value, fetchedAt: timestamped.fetchedAt)
            case .cached(let reason):
                return .stale(timestamped.value, fetchedAt: timestamped.fetchedAt, reason: reason)
            }
        case .failure(let error):
            guard let value, let fetchedAt else { return .failed(error) }
            return .stale(value, fetchedAt: fetchedAt, reason: error == .offline ? .offline : .refreshFailed)
        }
    }
}

extension SectionState: Equatable where Value: Equatable {}
