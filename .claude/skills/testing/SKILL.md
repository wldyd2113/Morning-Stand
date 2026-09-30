---
name: testing
description: Testing pitfalls for MorningStand — Swift Testing (@Test, arguments, expect/require macros, suites, parallelism, confirmation), MainActor ViewModel tests, deterministic time via injected DateProvider and TestClock, mocks, fixtures via Bundle.module, swift-snapshot-testing setup (fixed device/locale/timezone, record mode), XCTest UI tests with launch-argument mocks, coverage goals. Use before writing or reviewing any test.
---

# 테스트 주의사항

## 무엇을 어떤 도구로
| 대상 | 도구 | 위치 |
|---|---|---|
| Domain (UseCase, 출발 계산, 격자 변환, 파서) | Swift Testing | `Modules/Domain/Tests` (`swift test`로 빠르게) |
| Data (DTO 디코딩, Mapper, Repository, CacheStore, RateLimiter) | Swift Testing + fixture | `Modules/Data/Tests` |
| ViewModel | Swift Testing, `@MainActor` | `MoningseutendeuTests` |
| 화면 | swift-snapshot-testing | `MoningseutendeuTests/Snapshots` |
| 사용자 흐름 | XCTest UI | `MoningseutendeuUITests` |

커버리지 목표(안): Domain 90% 이상, Data 80% 이상, ViewModel 80% 이상. 숫자보다 **경계값과 실패 경로**를 우선한다.

## Swift Testing
- 여러 입력으로 같은 규칙을 검증할 때는 `@Test(arguments:)`를 쓴다. 도착 메시지 파싱, base_time 경계, 격자 변환, 등급 계산, 폴링 간격 표 등.
  - 두 컬렉션을 넘기면 **모든 조합(곱)**으로 돈다. 짝을 맞추려면 `zip(inputs, expected)`를 쓴다.
- `#expect`는 실패해도 계속 진행하고, `#require`는 실패하면 그 자리에서 멈춘다. 옵셔널을 풀 때는 `try #require(x)`를 쓴다.
- 에러 검증: `#expect(throws: AppError.quotaExceeded(api: .seoulBus)) { try await ... }`
- 테스트는 **기본적으로 병렬**로 돈다. 전역 상태, 싱글턴, 공유 UserDefaults, 공유 ModelContainer를 쓰지 않는다.
  - UserDefaults는 테스트마다 고유한 `suiteName`으로 만들고 끝나면 지운다.
  - 꼭 순서가 필요하면 `@Suite(.serialized)`를 쓴다.
- 이벤트가 몇 번 일어났는지 검증할 때(알림 예약, 스트림 방출)는 `confirmation(expectedCount:)`을 쓴다.
- `@Suite` struct의 `init`이 setUp 역할을 한다. 테스트마다 새 인스턴스가 만들어진다.
- 태그(`.tags(.parser)`)를 붙여 부분 실행이 쉽게 한다. 태그 정의는 테스트 타깃의 한 파일에 모은다.

## 시간 결정성
- 현재 시각은 `DateProvider`, 대기는 `any Clock<Duration>`로 주입받는다 (`swift-concurrency` 스킬 참고).
- 테스트용 고정 시각은 **KST 기준 헬퍼**로 만든다: `Date.kst(2026, 10, 1, 7, 30)`. 타임존이 다른 CI에서도 같은 결과가 나와야 한다.
- 폴링과 백오프는 TestClock으로 시간을 `advance(by:)`해서 검증한다. 실제 `Task.sleep`을 기다리는 테스트는 금지 (느리고 불안정하다).

## Mock
- 프로토콜마다 Mock을 하나씩 만든다 (`MockAPIClient`, `MockTransitRepository`, `MockPostureProvider` ...).
  - 호출 기록(`calls`)과 반환값 설정(`stub`)을 갖게 한다.
  - Mock이 actor 경계를 넘으면 `actor`로 만들거나 `Mutex`로 보호한다 (`@unchecked Sendable`은 사유 주석 필수).
- Mock은 테스트 전용 타깃이나 `TestSupport` 폴더에 둔다. Preview에서도 쓰는 것은 앱 타깃의 `PreviewSupport`에 둔다.
- `MockAPIClient`는 fixture 파일 이름으로 응답하게 해서, 실제 디코더와 Mapper를 함께 검증한다.

## ViewModel 테스트
- 테스트 함수나 Suite에 `@MainActor`를 붙인다.
- 검증할 것:
  - 초기 상태 → `start()` 후 각 섹션이 `.loaded`로 바뀌는지
  - 한 섹션만 실패할 때 나머지는 `.loaded`로 남는지 (**부분 실패**)
  - 캐시가 있을 때 실패하면 `.stale`로 가는지
  - 취소했을 때 `.failed`로 가지 않는지
  - 출발 시각이 지나면 다음 차량으로 넘어가는지
  - 폴링 조건(시간대, 스탠드, 포그라운드)에 따라 호출 횟수가 맞는지

## 스냅샷 테스트 (swift-snapshot-testing)
- 이미지 비교는 **기기, OS 버전, 스케일에 따라 달라진다.** 기록과 비교는 같은 시뮬레이터(기기 이름과 OS를 CLAUDE.md나 CI에 고정)에서 한다.
- 고정할 것:
  - 날짜: DateProvider
  - 로케일: `ko_KR`
  - 타임존: `Asia/Seoul`
  - 외관: light/dark, 야간 테마
  - Dynamic Type 크기
  - 번인 오프셋 0
  - 애니메이션 끄기
- 조합: 폼팩터(stand/planning) × 상태(loaded/stale/failed/loading) × 외관. 조합이 폭발하지 않게 대표 케이스를 고른다.
- 레퍼런스 이미지(`__Snapshots__/`)는 커밋한다. 레코드 모드로 다시 찍을 때는 **변경 이유를 커밋 메시지에 적는다.**
- Swift Testing에서는 `assertSnapshot(of:as:)`를 쓰고, 레코드 여부는 suite trait이나 `withSnapshotTesting(record:)`로 제어한다. 코드에 `record: true`를 남긴 채 커밋하지 않는다.
- 위젯 뷰와 Live Activity 뷰도 스냅샷을 찍는다 (family별 크기 지정).

## XCTest UI 테스트
- 앱을 `-UITest` launch argument로 실행하면 `AppDependencies`가 Mock 구성(고정 시각, fixture 응답, Mock posture)으로 조립된다. UI 테스트에서 실제 네트워크를 호출하지 않는다.
- 요소는 `accessibilityIdentifier`(`AppConstants.AccessibilityID`)로 찾는다. 화면 문구로 찾지 않는다.
- 대표 흐름만 다룬다: 즐겨찾기 추가 → 스탠드 모드 진입 → 카운트다운 표시, 오프라인 배지, 권한 거부 흐름.
- 대기는 `waitForExistence(timeout:)`으로 한다. `sleep`은 쓰지 않는다.

## 체크리스트
- [ ] 테스트가 네트워크, 실제 시각, 실제 위치에 의존하지 않는가
- [ ] 실패, 결측, 경계 케이스가 파라미터화되어 있는가
- [ ] 병렬 실행 시 서로 간섭하지 않는가
- [ ] 스냅샷 환경(기기, 로케일, 타임존)이 고정되어 있는가
