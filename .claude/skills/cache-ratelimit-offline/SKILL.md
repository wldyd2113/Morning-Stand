---
name: cache-ratelimit-offline
description: Pitfalls for MorningStand's actor-based CacheStore (memory + disk, per-API TTL, stale-while-revalidate, in-flight coalescing), actor-based RateLimiter (daily quotas, KST midnight reset, adaptive polling intervals), and NWPathMonitor offline detection. Use before implementing or changing caching, polling cadence, call budgets, or offline handling.
---

# 캐시 · 호출 한도 · 오프라인 주의사항

## CacheStore (actor)
- 메모리(Dictionary)와 디스크(Caches 디렉터리, 파일)를 2단계로 둔다. 디스크 캐시는 OS가 지울 수 있으므로 **없어도 동작해야** 한다.
- 캐시 키는 API 이름과 **정렬된 요청 파라미터**로 만든다. serviceKey는 키에서 뺀다.
- 저장 형식은 `CacheEnvelope<Value: Codable & Sendable> { value, savedAt, schemaVersion }`이다. 스키마가 바뀌면 이전 캐시는 버린다.
- TTL은 API별로 `PolicyConstants.CacheTTL`에 둔다. 예시:
  | 대상 | TTL(안) | 이유 |
  |---|---|---|
  | 버스·지하철 도착 | 20~30초 | 실시간성, 한도 |
  | 초단기실황·예보 | 10분 | 매시 갱신 |
  | 단기예보 | 1시간 | 3시간 간격 발표 |
  | 미세먼지 | 30분 | 매시 갱신 + 반영 지연 |
  | 정류소·측정소 목록 | 7일 | 거의 안 바뀜 |
- 조회 결과는 세 가지로 나눈다.
  - `fresh`: 그대로 쓴다.
  - `stale`: 즉시 보여주고 백그라운드에서 갱신한다 (stale-while-revalidate). 섹션 상태는 `.stale`로 둔다.
  - `miss`: 새로 요청한다.
- API가 실패했는데 오래된 캐시가 있으면 `.failed`가 아니라 **`.stale(value, reason: error)`**로 보여준다. 출근 앱에서는 빈 화면보다 "3분 전 기준" 정보가 낫다.
- 진행 중인 요청을 합친다 (`[Key: Task]`). 스탠드 화면과 위젯 갱신이 동시에 같은 API를 부르면 호출은 1건만 나가야 한다.
- 현재 시각은 주입받은 `DateProvider`로만 판단한다 → TTL 만료를 결정적으로 테스트할 수 있다.
- 디스크 I/O는 actor 안에서 짧게 하고, 큰 데이터(측정소 목록)는 인코딩·디코딩을 actor 밖에서 한다.

## RateLimiter (actor)
- API마다 **일일 카운터**를 두고, 기준은 **KST 자정 리셋**이다. 기기 타임존이 달라도 `Asia/Seoul` 달력으로 계산한다.
- 카운터는 앱을 재시작해도 유지되어야 하므로 UserDefaults(App Group)에 저장한다. 위젯은 네트워크를 쓰지 않으므로 앱만 증가시킨다.
- 요청 전에 `try await limiter.acquire(.seoulBus)`를 호출한다. 한도를 넘으면 `.rateLimited`를 던지고, Repository는 캐시(stale)로 대응한다.
- **재시도도 1건으로 센다.** 서버가 한도 초과 코드를 돌려주면 카운터를 한도까지 채워서 그날 호출을 멈춘다.
- 폴링 간격 자동 조절 (정책은 PolicyConstants에 둔다):
  - 출근 시간대 + 스탠드 모드 + 포그라운드일 때만 폴링하고, 그 외에는 수동 새로고침만 허용한다.
  - 남은 한도 비율에 따라 간격을 늘린다 (예: 50% 이상이면 기본값, 20~50%면 2배, 20% 미만이면 4배, 5% 미만이면 폴링을 멈추고 수동만).
  - 도착이 임박하면(예: 3분 이내) 간격을 줄이지 않는다. 대신 로컬 카운트다운으로 보간한다 (호출 절약).
  - 백그라운드나 화면 꺼짐 상태에서는 폴링하지 않는다.
- 남은 한도는 DEBUG 메뉴와 OSLog에서 확인할 수 있게 한다.
- 테스트: 한도 경계(999/1000/1001), 자정 리셋(23:59:59 → 00:00:00 KST), 동시 `acquire` 1,000회 시 정확한지, 간격 계산 표를 파라미터화 테스트한다.

## NWPathMonitor (오프라인 감지)
- `NetworkMonitor` 프로토콜 뒤에 숨긴다 (`var isOnline: Bool`, `var updates: AsyncStream<Bool>`). ViewModel은 Network 프레임워크를 모른다.
- `NWPathMonitor`는 `start(queue:)`에 전용 `DispatchQueue`를 넘긴다. 콜백을 AsyncStream으로 감쌀 때 `onTermination`에서 `cancel()`한다.
  - 한 번 `cancel()`한 monitor는 다시 시작할 수 없으므로 새로 만든다.
- `path.status == .satisfied`여도 실제 인터넷이 된다는 보장은 없다 (캡티브 포털 등). **요청을 막는 용도가 아니라 힌트**로만 쓴다.
  - 오프라인이면 폴링을 멈추고 "오프라인" 배지를 띄운다.
  - 온라인으로 바뀌면 stale 섹션만 즉시 갱신한다.
- 시뮬레이터의 네트워크 상태 변경은 부정확하다. 실제 기기(비행기 모드)로도 확인한다.
- `isExpensive`/`isConstrained`(저데이터 모드)이면 폴링 간격을 늘리는 것을 검토한다.

## 체크리스트
- [ ] 모든 API 호출이 RateLimiter → CacheStore → APIClient 순서로 지나가는가
- [ ] 실패했을 때 stale 캐시로 대체하는가
- [ ] 폴링은 조건(시간대, 스탠드, 포그라운드, 온라인)을 모두 만족할 때만 도는가
- [ ] 자정 리셋이 KST 기준인가
