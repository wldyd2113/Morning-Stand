# 모닝스탠드 (MorningStand)

폴더블 iPhone을 반쯤 접어 협탁에 세워두면 **"지금 나가면 몇 분 버스/지하철을 탈 수 있는지"**와 날씨·미세먼지를 한눈에 보여주는 출근 대시보드 앱.

- 핵심 값: **N분 뒤 출발 = 도착 예정 시간 − 정류장까지 도보 시간** (음수면 "놓침", 다음 차량으로 넘어감)
- 자체 서버 없음. 외부 공공 API + 온디바이스 로직만 사용
- 개인 포트폴리오, 약 4주. **완성도와 테스트 커버리지가 최우선**
- 답변·주석·문서는 한국어. 코드 식별자는 영어

| 폼팩터 | 화면 |
|---|---|
| 반접힘 (스탠드 모드) | 위: 시계·날씨·미세먼지 / 아래: 출발 카운트다운·도착 정보 |
| 펼침 (플래닝 모드) | 경로별 소요 시간 비교, 루틴·즐겨찾기 설정 |
| 닫힘 | 위젯, Live Activity, 로컬 알림 |

### 사용 API
| API | 형식 | 비고 |
|---|---|---|
| 서울 버스도착정보 / 정류소정보 (공공데이터포털) | XML | 개발계정 **일일 1,000건** |
| 경기도 버스도착정보 / 정류소 (공공데이터포털) | JSON·XML | 정류소 ID 체계가 서울과 다름 |
| 서울 지하철 실시간 도착 (서울 열린데이터광장) | JSON | 별도 키, `recptnDt` 보정 필요 |
| 기상청 단기예보 (초단기실황·초단기예보·단기예보) | JSON | **격자 X/Y** 좌표로 요청 |
| 에어코리아 대기오염정보 + 측정소정보 | JSON | 측정소 단위 조회 |

> API별 함정(필드, 에러 코드, 발표 시각 등)은 `korean-public-apis` 스킬에 정리했다. 필드명은 **실제 응답으로 확인한 뒤** fixture로 고정한다.

---

## 기술 스택 요약
Swift 6 (Strict Concurrency) · SwiftUI · Observation · SF Symbols · MVVM + Clean Architecture · **Alamofire** (URLSession 직접 사용 금지) · XMLCoder · Codable · Actor 기반 CacheStore/RateLimiter · NWPathMonitor · SwiftData · App Group UserDefaults · xcconfig · CoreLocation · WidgetKit · ActivityKit · App Intents · UserNotifications · BackgroundTasks · Swift Testing · XCTest(UI) · swift-snapshot-testing · OSLog · SPM 로컬 패키지 · GitHub Actions

기술별로 조심할 점은 **스킬**(`.claude/skills/`)에 나눠 두었다. 해당 기술을 건드리기 전에 관련 스킬을 먼저 읽는다 (맨 아래 표 참고).

---

## 폴더 구조 (목표)

```
moningseutendeu/
├─ CLAUDE.md
├─ Config/
│  ├─ Base.xcconfig              # 키 없는 공통 빌드 설정, #include? "Secrets.xcconfig"
│  ├─ Sample.xcconfig            # 키 템플릿 (커밋 O)
│  └─ Secrets.xcconfig           # 실제 키 (커밋 X)
├─ Modules/                      # 로컬 SPM 패키지 (※ .gitignore에 Packages/가 있어서 이름을 Modules로 함)
│  ├─ Domain/                    # Entity, UseCase, Repository 프로토콜. 외부 의존성 0개
│  │  ├─ Sources/Domain/{Entities,UseCases,Repositories,Services}
│  │  └─ Tests/DomainTests
│  └─ Data/                      # Domain 구현. Alamofire, XMLCoder 여기서만 import
│     ├─ Sources/Data/{Network,DTO,Mapper,Repositories,Cache,Persistence}
│     └─ Tests/DataTests (+ Fixtures/)
└─ Moningseutendeu/
   ├─ Moningseutendeu/           # 앱 타깃
   │  ├─ App/                    # @main, AppDependencies(조립), Scene
   │  ├─ Presentation/
   │  │  ├─ Stand/ Planning/ Settings/     # 기능별 View + ViewModel
   │  │  └─ Common/                        # SectionStateView 등 공용 컴포넌트
   │  ├─ Platform/               # CoreLocation, NWPathMonitor, Posture, Notification, BGTask, IdleTimer
   │  └─ Shared/
   │     ├─ Constants/           # APIConstants, PolicyConstants, AppConstants
   │     ├─ DesignSystem/        # DesignTokens (Color, Font, Spacing, Radius, Animation, Symbol)
   │     ├─ Error/               # AppError
   │     └─ Extensions/          # <Type>+<기능>.swift
   ├─ SharedAppGroup/            # 앱·위젯·Live Activity가 같이 쓰는 Snapshot, ActivityAttributes (양쪽 타깃 멤버십)
   ├─ MorningStandWidgets/       # WidgetKit + Live Activity 익스텐션
   ├─ MoningseutendeuTests/      # 앱 타깃 테스트 (ViewModel, 스냅샷)
   └─ MoningseutendeuUITests/
```

의존 방향: `Presentation → Domain ← Data`, `App`이 전부를 조립한다. **Domain은 아무것도 import하지 않는다** (Foundation만 허용).

### 공통 파일 분할 (카테고리별 한 파일)
| 파일 | 넣는 것 |
|---|---|
| `Shared/Constants/APIConstants.swift` (Data 패키지면 `Data/Network/APIConstants.swift`) | Base URL, 엔드포인트 경로, 쿼리 파라미터 키. API별 `enum` 네임스페이스 |
| `Shared/Constants/PolicyConstants.swift` | 캐시 TTL, 폴링 간격, 일일 호출 한도, 출근 시간대, 도보 속도, 타임아웃 |
| `Shared/Constants/AppConstants.swift` | App Group ID, UserDefaults 키, BGTask ID, 알림 ID, Logger 서브시스템·카테고리, 접근성 ID |
| `Shared/DesignSystem/DesignTokens.swift` | Color, Font, Spacing, Radius, Animation 시간, SF Symbol 이름 |
| `Shared/Error/AppError.swift` | 공통 에러와 사용자 메시지 매핑 |
| `Shared/Extensions/<Type>+<기능>.swift` | 타입별로 한 파일 |

> 파일 하나가 400줄을 넘으면 같은 폴더 안에서 `PolicyConstants+Cache.swift`처럼 extension으로 나눈다.

---

## 코드 규칙

1. **반복되는 것은 한 파일에서 관리한다**
   - 두 곳 이상에서 쓰이거나 의미가 있는 숫자·문자열(매직 넘버, URL, 키, 시간, 색, 간격, 심볼 이름)은 위 공통 파일에 둔다.
   - 새 코드를 쓰다가 **매직 넘버나 하드코딩 문자열이 보이면 그 자리에서 공통 파일로 옮긴다** (절차: 아래 "상수 추가").
   - 예외: `0`, `1`, 배열 인덱스, 테스트 코드의 입력값, 로컬라이즈 대상 사용자 문구(String Catalog에서 관리)
2. **네트워크는 Alamofire 기반 공통 `APIClient` 하나로만 호출한다.**
   - `URLSession.shared.data(...)` 같은 직접 호출은 금지. Repository는 `APIClient` **프로토콜**에만 의존한다.
   - `URLSessionConfiguration`으로 Alamofire `Session`을 설정하는 것은 허용한다.
3. **View는 ViewModel만 안다. ViewModel은 UseCase(또는 Repository 프로토콜)만 안다.**
   - View에 비즈니스 로직 금지. 계산, 분기, 포매팅은 ViewModel이 표시용 모델(`...DisplayModel`)로 만들어 넘긴다.
   - View에서 `@Query`, Repository, APIClient를 직접 쓰지 않는다.
4. **모든 ViewModel은 `@MainActor @Observable final class`**
   - `ObservableObject`, `@Published`는 쓰지 않는다.
   - 의존성은 프로토콜로 받아 생성자로 주입한다 (APIClient, `any Clock<Duration>`, `DateProvider`, `PostureProvider`, `LocationProvider`, `NetworkMonitor`).
5. **새 기능에는 테스트를 같이 작성한다.**
   - UseCase, 파서, Mapper, actor는 단위 테스트(Swift Testing), ViewModel은 상태 전이 테스트, 화면은 스냅샷 테스트로 확인한다.

### 추가 규칙
- 섹션 상태는 공통 타입 `SectionState<Value>` (`.idle / .loading / .loaded(Value, fetchedAt) / .stale(Value, fetchedAt, reason) / .failed(AppError)`)로 표현한다.
- "현재 시각"은 `Date()`를 직접 부르지 않고 `DateProvider`를 주입받는다. 대기(sleep)·틱은 `any Clock<Duration>`를 주입받는다.
- 로그는 `Logger(subsystem:category:)`로만 남긴다. `print` 금지. **API 키가 들어간 URL은 로그에 남기지 않는다.**
- 파일 하나에는 주요 타입 하나. 파일 이름과 타입 이름을 같게 한다.
- `.gitignore`가 `*Key.swift`, `*Keys.swift`, `*Secret(s).swift`, `*APIKey*.swift`를 무시한다. 이런 이름의 파일은 **조용히 커밋에서 빠지므로** 쓰지 않는다 (예: 키 읽는 코드는 `SecretsReader.swift`).
- Git 커밋 메시지는 Conventional Commits 형식(`feat:`, `fix:`, `test:`, `chore:`, `docs:`, `refactor:`)을 따른다.

---

## 주의사항

| # | 항목 | 지킬 것 |
|---|---|---|
| 1 | Swift 6 Strict Concurrency | Sendable 경고 0개 유지. `@unchecked Sendable`은 lock(`Mutex`)으로 보호할 때만 쓰고 이유를 주석으로 남긴다. Alamofire 응답 타입(DTO)은 `Decodable & Sendable` 값 타입으로 만든다 |
| 2 | SwiftData | `ModelContext`와 `@Model` 인스턴스를 actor 경계 너머로 넘기지 않는다. 백그라운드 작업은 `@ModelActor`로 하고, 경계를 넘길 때는 도메인 struct나 `PersistentIdentifier`로 넘긴다 |
| 3 | 서울 버스 1,000건/일 | **스탠드 모드이면서 출근 시간대일 때만** 폴링한다. 모든 호출은 `RateLimiter`를 거치고, 남은 한도에 따라 폴링 간격을 늘린다 |
| 4 | 지하철 시간 보정 | 남은 시간 = `barvlDt − (now − recptnDt)`, 0 미만이면 0으로 자른다. `recptnDt`는 KST로 파싱한다 |
| 5 | 도착 메시지 문자열 | "곧 도착", "운행종료", "출발대기", "N분M초후[K번째 전]" 등을 enum으로 파싱한다. 모르는 문자열은 `.unknown(raw)`로 두고 크래시 없이 표시한다 |
| 6 | 기상청 좌표 | 위경도가 아닌 **격자 X/Y**로 요청한다. `base_date`/`base_time`은 API별 발표·제공 시각에 맞춰 계산한다 |
| 7 | 부분 실패 | 한 API가 실패해도 다른 섹션은 정상 표시. 섹션별 loaded / stale / failed 상태를 갖고, TaskGroup 자식은 `Result`로 격리한다 |
| 8 | 위젯 | 네트워크 호출 없이 **App Group 스냅샷만 읽는다**. 메모리 한도와 갱신 예산이 있다 |
| 9 | Live Activity | 최대 8시간 동안 활성, ContentState 4KB, 업데이트 빈도 제한. 서버 푸시가 없으므로 `Text(timerInterval:)`로 카운트다운한다 |
| 10 | BGAppRefreshTask | 실행 시점이 보장되지 않는다. 핵심 기능은 여기에 의존하지 않고 "있으면 좋은" 미리 갱신으로만 쓴다 |
| 11 | API 키 | xcconfig → Info.plist → `SecretsReader`로 주입한다. `Secrets.xcconfig`는 커밋 금지 (`.gitignore` 확인) |
| 12 | 화면 꺼짐 방지 | `isIdleTimerDisabled`는 스탠드 화면에서만 켠다. 화면을 떠날 때, 백그라운드로 갈 때 **반드시 끈다** |

### 현재 프로젝트 설정 TODO (2026-09-30 기준)
- [ ] `SWIFT_VERSION = 5.0` → **6.0**으로 올리기
- [ ] 앱 타깃 `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` 유지. Domain/Data 패키지는 기본(nonisolated)으로 둔다 → `swift-concurrency` 스킬 참고
- [ ] `.gitignore`의 `*.xcconfig`를 `Config/Secrets.xcconfig`로 좁혀서 `Base.xcconfig`가 커밋되게 하기
- [ ] `Modules/Domain`, `Modules/Data` 로컬 패키지 생성 후 앱 타깃에 연결
- [ ] Widget Extension 타깃, App Group(`group.com.jiyong.Moningseutendeu`) 추가

---

## 반복 작업 절차

> 순서대로 진행하고, 끝나면 "커밋 전 점검"을 돈다.

### A. 새 기능 추가 (View / ViewModel / UseCase / Repository / 테스트)
1. **Domain** (`Modules/Domain`)
   - `Entities/<Name>.swift`: `struct`, `Sendable`, `Equatable`
   - `Repositories/<Name>Repository.swift`: `protocol ...: Sendable`, 메서드는 `async throws`
   - `UseCases/<Verb><Name>UseCase.swift`: `struct`, 의존성은 생성자로 주입, `func callAsFunction(...)` 또는 `execute`
2. **Data** (`Modules/Data`): `Repositories/Default<Name>Repository.swift`가 APIClient, CacheStore, RateLimiter, Mapper를 조합한다 (API가 필요하면 절차 B).
3. **Presentation** (`Presentation/<Feature>/`)
   - `<Feature>ViewModel.swift`: `@MainActor @Observable final class`
     - 상태는 `SectionState`로 둔다
     - 비동기 작업은 `func load() async` / `func start() async`로 만들어 View의 `.task`에서 부른다 (그래야 취소가 자동으로 된다)
   - `<Feature>View.swift`: ViewModel이 만든 DisplayModel만 그린다. 숫자·색·간격은 `DesignTokens`에서 가져온다.
   - `#Preview`에는 Mock 의존성을 넣는다.
4. **조립**: `App/AppDependencies.swift`에 실제 구현을 등록하고, 테스트·UI 테스트용 Mock 구성(`-UITest` launch argument)도 함께 추가한다.
5. **테스트**: UseCase(파라미터화), Repository(Mock APIClient + fixture), ViewModel(상태 전이, 부분 실패, 취소), View 스냅샷(loaded/stale/failed × light/dark × 폼팩터)

### B. 공공 API 엔드포인트 추가
1. 명세서를 확인하고 **실제 응답을 한 번 받아** `Modules/Data/Tests/DataTests/Fixtures/<api>_<case>.xml|json`에 저장한다.
   - 키, 개인정보는 지운다
   - 정상, 결과 없음, 에러 코드, 엣지 문자열 케이스를 모두 모은다 (절차 G)
2. `APIConstants`에 Base URL, 경로, 쿼리 키를 등록한다.
3. `Endpoint` 정의: method, path, parameters, 응답 포맷(XML/JSON), 사용할 키 종류.
4. **DTO** (`DTO/<Api>DTO.swift`): 응답 그대로의 `Decodable & Sendable` struct. 숫자도 문자열로 올 수 있으니 우선 `String?`로 받는다.
5. **Mapper** (`Mapper/<Api>Mapper.swift`): DTO → Domain Entity. 문자열 파싱, 시간 보정, 결측값 처리는 여기서 하고, 순수 함수로 만든다.
6. **에러 매핑**: HTTP 200인데 본문에 에러 코드가 있는 경우(`resultCode`, `headerCd`, `INFO-xxx`)를 `AppError`로 바꾼다. "결과 없음"은 에러가 아니라 빈 배열로 처리한다.
7. `PolicyConstants`에 **TTL**, **일일 한도**, **폴링 간격**을 등록하고 Repository에서 CacheStore와 RateLimiter를 연결한다.
8. **테스트**: fixture 디코딩, Mapper 파라미터화 테스트, 에러 코드 매핑, 캐시 적중/만료, 한도 초과 시 동작.

### C. 상수·디자인 토큰 추가
1. 알맞은 공통 파일을 고른다 (위 "공통 파일 분할" 표).
2. `enum` 네임스페이스 안에 `static let`으로 추가하고, 단위를 이름에 드러낸다 (`busPollingInterval: Duration`, `walkingSpeedMetersPerSecond`).
3. 기존 하드코딩을 찾아 교체한다. 예:
   `grep -rnE '"https?://|[^.0-9][0-9]{2,}[^0-9]|Color\(red|\.padding\([0-9]|systemName: "' --include=*.swift`
4. 교체한 파일의 빌드와 테스트를 확인한다.

### D. 테스트 작성
| 대상 | 방법 |
|---|---|
| UseCase·Mapper·파서·격자 변환 | `@Test(arguments:)` 파라미터화, 순수 입력 → 출력 |
| actor (CacheStore, RateLimiter) | 고정 `DateProvider`, TestClock으로 TTL 만료·자정 리셋·동시 호출을 결정적으로 검증 |
| Repository | Mock APIClient가 fixture를 반환 → 도메인 결과와 에러 매핑 확인 |
| ViewModel | `@MainActor` 테스트. Mock UseCase로 loading → loaded / stale / failed 전이, 부분 실패, 취소 확인 |
| View | swift-snapshot-testing. 고정 날짜, 로케일 `ko_KR`, 타임존 `Asia/Seoul`, 고정 기기에서 찍는다 |
| 사용자 흐름 | XCTest UI 테스트, `-UITest` launch argument로 Mock 주입, 접근성 ID는 `AppConstants`에서 가져온다 |

### E. 커밋 전 점검
1. **빌드**
   ```
   xcodebuild build -project Moningseutendeu/Moningseutendeu.xcodeproj -scheme Moningseutendeu -destination 'platform=iOS Simulator,name=<기기>'
   ```
   경고 중 Sendable, concurrency 관련 경고가 0개인지 확인한다.
2. **패키지 테스트**: `swift test --package-path Modules/Domain`, `swift test --package-path Modules/Data`
3. **앱 테스트**: `xcodebuild test ...` (스냅샷 포함)
4. **시크릿 검사**
   - `git diff --cached | grep -iE 'serviceKey=|apikey|[A-Za-z0-9%+/]{40,}={0,2}'`
   - `git status`에 `Secrets.xcconfig`가 없는지 확인한다
5. **하드코딩 검사**: C-3의 grep을 변경한 파일에 돌린다.
6. **리뷰 에이전트**: `git diff --name-only`로 변경 파일 목록을 뽑아 `mvvm-reviewer`에 넘기고, 동시성 코드가 있으면 `concurrency-reviewer`에도 넘긴다 (병렬로 실행해도 된다).
7. 🔴 지적은 고치고, 🟡 지적은 고치거나 사유를 남긴 뒤 커밋한다.

### F. API 키 설정 (처음 한 번, 또는 새 키를 받았을 때)
1. `cp Config/Sample.xcconfig Config/Secrets.xcconfig`로 복사하고 키를 채운다. 공공데이터포털 키는 **Decoding 키**를 쓴다.
2. `Base.xcconfig`에서 `#include? "Secrets.xcconfig"`로 불러온다 (`?`가 있으면 파일이 없어도 CI 빌드가 된다).
3. Info.plist에 `DATA_GO_KR_SERVICE_KEY = $(DATA_GO_KR_SERVICE_KEY)` 형태로 등록한다.
4. `SecretsReader`에서 `Bundle.main.object(forInfoDictionaryKey:)`로 읽는다. 값이 비어 있으면 DEBUG에서 `assertionFailure`를 낸다.
5. `git check-ignore -v Config/Secrets.xcconfig`로 무시되는지 확인한다.

### G. API 응답 fixture 수집
1. 개발계정 한도를 아끼기 위해 **한 케이스당 한 번만** 호출해서 저장한다.
2. 수집 대상: 정상 여러 건, 한 건, 0건(결과 없음), 에러 코드, "곧 도착", "운행종료", "출발대기", 결측값(`-`, `""`, `+900` 이상).
3. 키, 기기 위치 등 민감한 값은 지우거나 가짜 값으로 바꾼다. 파일 이름은 `<api>_<case>.<ext>`.
4. 테스트에서는 `Bundle.module`로 불러온다 (Package.swift에 `resources: [.process("Fixtures")]`).

### H. SwiftData 모델 추가
1. `Data/Persistence/Models/<Name>Model.swift`: `@Model final class`. 도메인 Entity와는 별도 타입으로 둔다.
2. `SchemaV<n>`(`VersionedSchema`)에 모델을 등록하고, 스키마가 바뀌면 `MigrationPlan`에 단계를 추가한다.
3. `@ModelActor actor <Name>Store`에 CRUD를 두고, 반환 타입은 도메인 struct로 한다.
4. Repository 프로토콜은 Domain에 두고, 구현은 Store를 감싼다.
5. 테스트는 `ModelConfiguration(isStoredInMemoryOnly: true)`로 만든 컨테이너를 쓴다.

---

## 서브에이전트 (`.claude/agents/`)

| 에이전트 | 언제 | 권한 |
|---|---|---|
| `mvvm-reviewer` | 기능 구현이 끝났을 때, 커밋 전 (필수) | 읽기 전용 |
| `concurrency-reviewer` | actor, Task, TaskGroup, AsyncStream, Sendable 관련 코드를 바꿨을 때 | 읽기 전용 |
| `api-integration` | 새 공공 API 연동, DTO/Mapper/에러 매핑, 캐시·RateLimiter 연결 | 쓰기 |
| `widget-liveactivity` | 위젯, Live Activity, App Intents, App Group 작업 | 쓰기 |
| `test-writer` | 테스트 작성·보강, 커버리지 올리기 | 쓰기 |
| `stand-mode-ui` | 스탠드/플래닝 화면, PostureProvider, 번인 방지, 야간 테마 | 쓰기 |
| `location-geo` | CoreLocation, 기상청 격자 변환, 가까운 정류장·측정소 찾기 | 쓰기 |

## 스킬 = 기술별 주의사항 (`.claude/skills/`)

해당 기술을 건드리는 작업을 시작하기 전에 읽는다.

| 스킬 | 다루는 기술 |
|---|---|
| `swift-concurrency` | Swift 6, actor, Sendable, async let, TaskGroup, AsyncStream, Clock, 취소 |
| `swiftui-observation` | SwiftUI, @Observable, MVVM 바인딩, SF Symbols, 접근성 |
| `alamofire-networking` | Alamofire, APIClient, XMLCoder, Codable, 에러 매핑, 로그 마스킹 |
| `korean-public-apis` | 서울·경기 버스, 지하철, 기상청, 에어코리아 API의 함정 |
| `cache-ratelimit-offline` | CacheStore, RateLimiter, 폴링 전략, NWPathMonitor |
| `swiftdata-persistence` | SwiftData, ModelActor, 마이그레이션, App Group UserDefaults 스냅샷 |
| `secrets-xcconfig` | xcconfig, Info.plist 주입, 키 보안, .gitignore |
| `location-kma-grid` | CoreLocation, 권한, 위경도 → 격자 변환, 최근접 검색 |
| `widgetkit-liveactivity` | WidgetKit, ActivityKit, Dynamic Island, App Intents, App Groups |
| `notifications-background` | UserNotifications, BGAppRefreshTask |
| `stand-mode` | PostureProvider, isIdleTimerDisabled, TimelineView, 번인 방지, 야간 테마 |
| `testing` | Swift Testing, XCTest UI, swift-snapshot-testing, Clock/Mock 주입 |
| `spm-ci-logging` | SPM 로컬 패키지, GitHub Actions, 커버리지, OSLog |
