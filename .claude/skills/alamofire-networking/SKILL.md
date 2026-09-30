---
name: alamofire-networking
description: Alamofire-based APIClient pitfalls for MorningStand — single Session, async serializingDecodable, Sendable DTOs, XMLCoder as DataDecoder, public-data service key double-encoding, HTTP-200 error bodies, AppError mapping, retry, and redacting keys from OSLog. Use before adding or changing APIClient, Endpoint, DTO decoding, or network error handling.
---

# Alamofire 네트워킹 주의사항

## 구조
```
Repository ──(protocol)──▶ APIClient ──▶ AlamofireAPIClient ── Session(1개)
                                          ├─ RequestInterceptor (재시도)
                                          └─ EventMonitor (OSLog, 키 마스킹)
```
- `protocol APIClient: Sendable { func send<T: Decodable & Sendable>(_ endpoint: Endpoint<T>) async throws(AppError) -> T }` 형태로 정의한다. 에러 타입은 typed throws로 고정할지 팀 규칙으로 정한다.
- Repository는 이 프로토콜만 안다. `import Alamofire`는 **Data 패키지의 Network 폴더에서만** 허용한다.
- `AF`(전역 Session)를 쓰지 않는다. `AlamofireAPIClient`가 `Session`을 하나 만들어 소유한다.
  - 타임아웃은 `URLSessionConfiguration`으로 지정하고, 값은 `PolicyConstants`에 둔다.
  - 캐시는 CacheStore가 담당하므로 `requestCachePolicy = .reloadIgnoringLocalCacheData`로 URLCache와 이중 캐시가 생기지 않게 한다.
- URLSession을 직접 호출하는 것은 금지다. 설정 객체(`URLSessionConfiguration`)를 쓰는 것만 허용한다.

## async/await 사용
```swift
let task = session.request(url, parameters: params, encoding: URLEncoding.queryString)
    .validate(statusCode: 200..<300)
    .serializingDecodable(T.self, decoder: decoder)
let response = await task.response        // DataResponse<T, AFError>
```
- `.value`는 `AFError`를 던진다. `.response`로 받아 `result`, `response?.statusCode`, `data`를 보고 `AppError`로 매핑하는 편이 에러 매핑에 유리하다.
- `T`는 `Decodable & Sendable`이어야 한다. DTO는 struct로 만든다.
- 요청 전에 `try Task.checkCancellation()`을 하고, 취소되었으면 `AFError.explicitlyCancelled`를 `CancellationError` 계열로 바꿔 위로 올린다 (실패 상태로 표시하지 않는다).
- 공공 API의 `Content-Type`이 `text/xml;charset=UTF-8`, `text/html` 등으로 제각각이다. `validate(contentType:)`은 쓰지 않거나 넓게 잡는다.

## 공공데이터포털 serviceKey (가장 흔한 버그)
- 포털은 **Encoding 키와 Decoding 키**를 준다. Alamofire `parameters`는 값을 퍼센트 인코딩하므로 **Decoding 키**를 넣어야 한다.
  - Encoding 키를 넣으면 이중 인코딩되어 `SERVICE_KEY_IS_NOT_REGISTERED_ERROR`가 난다.
  - Decoding 키에 들어 있는 `+`, `/`, `=`를 Alamofire가 올바르게 인코딩하는지 테스트로 고정한다.
- 서울 지하철 키는 쿼리가 아니라 **URL 경로**에 들어간다 (`/api/subway/{KEY}/json/...`). 경로 조립은 Endpoint에서 한다.

## XML 디코딩 (XMLCoder)
- Alamofire의 `DataDecoder`는 Sendable을 요구하는데, `XMLDecoder`는 클래스라 공유하기 어렵다. 호출할 때마다 새 디코더를 만드는 래퍼를 둔다.
  ```swift
  struct XMLDataDecoder: DataDecoder {
      func decode<D: Decodable>(_ type: D.Type, from data: Data) throws -> D {
          let decoder = XMLDecoder()
          decoder.shouldProcessNamespaces = false
          decoder.trimValueWhitespaces = true
          return try decoder.decode(type, from: data)
      }
  }
  ```
- 결과가 한 건이면 XML에 `<itemList>`가 하나만 온다. `[Item]`으로 선언하면 XMLCoder가 배열로 받아주지만, **0건이면 키 자체가 없으므로** `decodeIfPresent ?? []`로 받는다.
- 숫자 필드가 빈 문자열(`<traTime1></traTime1>`)이나 `-`로 올 수 있다. DTO에서는 `String?`로 받고 Mapper에서 변환한다. DTO에서 `Int`로 받으면 전체 디코딩이 실패한다.
- 공공 API 에러 응답은 루트 태그가 다르다 (`<OpenAPI_ServiceResponse>`). 정상 DTO로 디코딩이 실패하면 에러 DTO로 한 번 더 시도해서 원인 코드를 뽑는다.

## JSON 디코딩 (Codable)
- 기상청과 에어코리아는 `dataType=JSON` / `returnType=json` 파라미터를 줘야 JSON으로 온다. 빠뜨리면 XML이 와서 디코딩이 실패한다.
- 숫자가 문자열로 오는 필드(`"fcstValue": "3"`, `"pm10Value": "-"`)가 많다. DTO는 `String`으로 받는다.
- `keyDecodingStrategy`를 전역으로 바꾸지 말고 `CodingKeys`로 명시한다 (필드명이 제각각이다).
- 날짜 문자열은 `Date.ParseStrategy`에 `timeZone: Asia/Seoul`, `locale: en_US_POSIX`를 지정해 Mapper에서 변환한다.

## 에러 매핑 (`AppError`)
| 상황 | 매핑 |
|---|---|
| 오프라인 (`URLError.notConnectedToInternet` 등) | `.offline` |
| 타임아웃 | `.timeout` |
| HTTP 4xx/5xx | `.server(status:)` |
| HTTP 200 + 본문 에러 코드 (키 오류, 한도 초과) | `.apiKeyInvalid`, `.quotaExceeded(api:)`, `.api(code:message:)` |
| 결과 없음 코드 | 에러가 아님 → 빈 결과 |
| 디코딩 실패 | `.decoding(api:)` + 원문 일부를 DEBUG 로그로 |
| RateLimiter 거부 | `.rateLimited(api:, retryAfter:)` |
| 취소 | 에러로 올리지 않는다 (`CancellationError`) |

- `AppError`는 `Sendable, Equatable`로 만든다. 사용자에게 보여줄 메시지는 Presentation에서 매핑한다.

## 재시도
- `RetryPolicy`는 **타임아웃과 5xx만**, 최대 1~2회, 백오프를 두고 재시도한다. 횟수와 간격은 `PolicyConstants`에 둔다.
- 재시도도 호출 한도를 소모한다. RateLimiter에 재시도까지 포함해서 카운트한다.
- 키 오류, 한도 초과, 4xx는 재시도하지 않는다.

## 로깅 (EventMonitor + OSLog)
- 요청 URL에 `serviceKey`가 들어간다. 로그를 남기기 전에 **쿼리와 경로의 키를 `***`로 마스킹**한다. 마스킹 함수는 단위 테스트한다.
- `Logger`의 기본 privacy는 동적 문자열에 대해 `.private`이다. 마스킹한 URL, API 이름, 상태 코드, 소요 시간만 `.public`으로 남긴다.

## ATS
- 공공 API 중 HTTPS를 지원하지 않는 곳이 있다 (지하철 `swopenAPI.seoul.go.kr` 등 — 실제 확인 필요).
- `NSAllowsArbitraryLoads`는 쓰지 않는다. 해당 도메인만 `NSExceptionDomains`에 등록한다.

## 체크리스트
- [ ] Repository에 `import Alamofire`가 없는가
- [ ] DTO는 Sendable struct이고 숫자는 `String?`로 받는가
- [ ] 200 응답 안의 에러 코드를 확인하는가
- [ ] 키가 로그에 남지 않는가
- [ ] 재시도가 한도에 포함되는가
