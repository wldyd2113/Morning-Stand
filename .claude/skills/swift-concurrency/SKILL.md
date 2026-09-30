---
name: swift-concurrency
description: Swift 6 Strict Concurrency pitfalls for MorningStand — actor isolation, Sendable, default MainActor isolation, async let/TaskGroup failure isolation, cancellation, AsyncStream polling/ticks, Clock injection. Use before writing or reviewing any actor, Task, TaskGroup, AsyncStream, Sendable conformance, or concurrency warning fix.
---

# Swift 6 동시성 주의사항

## 1. 프로젝트 격리 설정
- 앱 타깃은 `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`다. 표시하지 않은 타입과 함수는 **전부 MainActor에 묶인다**.
  - 앱 타깃 안의 Platform 서비스(Location, NetworkMonitor 등)를 MainActor 밖에서 돌려야 하면 `nonisolated`를 명시하거나 `actor`로 만든다.
  - 앱 타깃에 둔 DTO/값 타입이 백그라운드에서 쓰인다면 `nonisolated struct`로 선언해야 경고가 없다.
- `Modules/Domain`, `Modules/Data` 패키지는 기본 격리(nonisolated)로 둔다. 순수 로직과 네트워크는 메인 스레드와 상관없다.
- `SWIFT_VERSION`을 6으로 올린 뒤 경고가 아니라 **에러**로 나오는 것이 정상이다. `@preconcurrency import`는 서드파티가 Sendable을 지원하지 않을 때만 쓰고 이유를 주석으로 남긴다.
- Approachable Concurrency(`NonisolatedNonsendingByDefault`)가 켜져 있으면 `nonisolated async` 함수가 **호출한 쪽의 actor에서** 실행된다.
  - 무거운 파싱처럼 반드시 백그라운드에서 돌아야 하는 함수는 `@concurrent`를 붙인다.
  - 빌드 설정을 확인하고 켜져 있는지 여부를 이 문서에 반영한다.

## 2. Sendable
- Domain Entity, DTO, Endpoint, 에러 타입은 모두 **값 타입 + `Sendable`**로 만든다. `class` DTO는 쓰지 않는다.
- Repository, UseCase, APIClient 프로토콜은 `: Sendable`을 요구한다. 구현체는 `struct`나 `final class`(불변 `let`만)로 둔다.
- 클로저를 저장하거나 넘길 때는 `@Sendable`을 붙인다 (`DateProvider`는 `@Sendable () -> Date`).
- `@unchecked Sendable`은 내부 상태를 `Mutex`(Synchronization)로 보호할 때만 허용하고, 사유를 주석으로 남긴다.
- 전역·static 가변 변수는 금지. 상수는 `static let`으로 두고 타입이 Sendable이어야 한다 (`DateFormatter`를 static으로 공유하면 안 된다 → `Date.FormatStyle`이나 `Date.ParseStrategy`를 쓴다).
- `XMLDecoder`, `JSONDecoder`, `DateFormatter`는 Sendable이 아니다. 공유하지 말고 호출할 때마다 만들거나 actor 안에 가둔다.

## 3. Actor
- **재진입(reentrancy)**: `await` 앞뒤로 actor 상태가 바뀔 수 있다. `await` 뒤에는 상태를 다시 확인한다.
- CacheStore 같은 곳에서 같은 키로 동시에 요청이 들어오면 `[Key: Task<Value, Error>]`에 진행 중인 요청을 저장해 **하나로 합친다** (중복 API 호출은 곧 한도 낭비다).
- actor 안에서 오래 걸리는 동기 작업(큰 XML 파싱)을 하지 않는다. 그동안 다른 호출이 전부 막힌다.
- `nonisolated` 프로퍼티는 불변 `let` + Sendable일 때만 쓴다.

## 4. 병렬 호출과 실패 격리 (부분 실패)
- 대시보드는 버스, 지하철, 날씨, 미세먼지를 **동시에** 부르되, 하나가 실패해도 나머지는 표시해야 한다.
- `withThrowingTaskGroup`에서 `try await group.next()`가 던지면 그룹을 빠져나가면서 **나머지 자식이 전부 취소된다**. 이것은 부분 실패 요구사항과 맞지 않는다.
  ```swift
  await withTaskGroup(of: DashboardSection.self) { group in
      group.addTask { .weather(await Result { try await weather.fetch() }) }
      group.addTask { .air(await Result { try await air.fetch() }) }
      for await section in group { apply(section) }   // 먼저 끝난 섹션부터 반영
  }
  ```
  (`Result`의 async 이니셜라이저는 없으므로 `Result.init(catching:)` async 버전을 Extension으로 하나 만든다 → `Shared/Extensions/Result+Async.swift`)
- `async let`도 한쪽이 던지면 스코프를 빠져나가면서 나머지가 취소된다. 격리가 필요하면 각각을 `Result`로 감싼다.
- 섹션 결과를 `.failed`로 바꿀 때 **`CancellationError`는 실패로 치지 않는다** (화면을 떠난 것일 뿐). 상태를 그대로 두거나 무시한다.

## 5. 취소
- ViewModel의 비동기 작업은 View의 `.task { await vm.start() }` / `.task(id:)`에서 시작한다. 그래야 화면이 사라질 때 자동으로 취소된다.
- ViewModel에서 `Task { }`를 직접 만들면 반드시 핸들을 저장해 두고 `stop()`이나 `deinit`에서 `cancel()`한다.
  - MainActor 클래스의 `deinit`은 nonisolated라서 격리된 상태에 접근할 수 없다. `isolated deinit`을 쓰거나 핸들을 `nonisolated let`으로 둔다.
- 폴링 루프는 `while !Task.isCancelled`와 `try await clock.sleep(for:)`로 짠다. sleep이 `CancellationError`를 던지면 그대로 빠져나간다.
- Alamofire 요청은 Swift Task가 취소되면 같이 취소된다 (`serializingDecodable` 사용 시). 취소 후 결과를 상태에 반영하지 않는다.
- `Task.detached`는 쓰지 않는다. 필요하면 `@concurrent` 함수로 대신한다.

## 6. AsyncStream (폴링, 카운트다운 틱)
- 스트림은 `AsyncStream.makeStream(of:bufferingPolicy:)`로 만든다. 틱이나 최신 값만 의미 있는 스트림은 `.bufferingNewest(1)`로 둔다.
- 내부에서 만든 Task는 `continuation.onTermination`에서 **반드시 cancel**한다. 안 그러면 소비자가 사라진 뒤에도 폴링이 계속되어 한도를 소모한다.
- `AsyncStream`은 소비자 하나를 전제로 한다. 여러 곳에서 구독해야 하면 소유자(actor)가 소비자별로 스트림을 만들어 준다.
- 카운트다운 화면은 1초 틱 스트림보다 `TimelineView`나 `Text(timerInterval:)`가 싸다. 스트림은 "다시 계산해야 하는 시점"(예: 분 단위)에만 쓴다.

## 7. 시간 주입
- "지금 몇 시인가"와 "얼마나 기다리나"는 서로 다른 개념이다.
  - 현재 시각: `DateProvider`(`@Sendable () -> Date`)를 주입한다 → 도착 시간 보정, TTL, 출근 시간대 판정에 쓴다.
  - 대기·틱: `any Clock<Duration>`를 주입한다 (실제는 `ContinuousClock`) → 폴링 간격, 재시도 백오프에 쓴다.
- 테스트에서는 수동으로 시간을 전진시키는 TestClock을 쓴다 (직접 구현하거나 pointfree `swift-clocks` 사용). `Task.sleep`을 직접 호출하면 결정적으로 테스트할 수 없다.

## 체크리스트
- [ ] 새 타입이 스레드를 넘나드는가? 그렇다면 Sendable인가
- [ ] 부분 실패 경로에서 `CancellationError`를 실패로 표시하지 않는가
- [ ] 저장한 Task는 모두 cancel되는가, AsyncStream에 `onTermination`이 있는가
- [ ] `Date()`, `Task.sleep`을 직접 호출하지 않았는가
- [ ] actor 메서드에서 `await` 뒤에 상태를 다시 확인하는가
