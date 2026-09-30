---
name: spm-ci-logging
description: Tooling pitfalls for MorningStand — local SPM packages (Domain/Data) under Modules/, Package.swift settings (tools version, platforms incl. macOS for fast swift test, resources, isolation), dependency pinning (Alamofire, XMLCoder, snapshot-testing), GitHub Actions CI (Xcode selection, simulator pinning, missing secrets, coverage via xccov, caching), and OSLog conventions (subsystem/category, privacy, signposts). Use before editing Package.swift, project dependencies, CI workflows, or logging.
---

# SPM · CI · 로깅 주의사항

## 로컬 SPM 패키지
- 위치는 `Modules/Domain`, `Modules/Data`다. **`Packages/`는 .gitignore에 걸리므로 쓰지 않는다.**
- `// swift-tools-version: 6.x`로 두면 Swift 6 언어 모드가 기본이다.
- `platforms`에 iOS와 함께 **macOS도 넣으면** `swift test --package-path Modules/Domain`로 시뮬레이터 없이 몇 초 만에 테스트를 돌릴 수 있다.
  - 이를 위해 Domain과 Data에서 UIKit이나 iOS 전용 API를 쓰지 않는다.
  - Data가 iOS 전용 API를 써야 하면 그 부분은 앱 타깃의 Platform으로 뺀다.
- 의존성 규칙:
  - Domain은 **외부 의존성 0개**다.
  - Data만 Alamofire와 XMLCoder를 의존한다.
  - 앱 타깃은 Domain과 Data를 의존한다.
  - 테스트 타깃만 swift-snapshot-testing을 의존한다.
- 패키지 기본 격리는 nonisolated로 둔다 (`swift-concurrency` 스킬 참고). 필요하다면 `swiftSettings`로 추가 기능 플래그를 켜고 이 문서에 기록한다.
- fixture는 `resources: [.process("Fixtures")]`로 등록하고 `Bundle.module`로 읽는다. 디렉터리 구조를 그대로 유지하려면 `.copy`를 쓴다.
- `public` 접근 제어: 패키지 밖에서 쓰는 타입과 이니셜라이저는 명시적으로 `public`으로 한다. struct의 멤버와이즈 init은 자동으로 public이 되지 않는다.
- 버전은 `from:`(다음 메이저 전까지)으로 지정하고, `Package.resolved`는 **커밋한다** (재현 가능한 빌드).
- 현재 `.gitignore`에 `.swiftpm/`이 있는데, 로컬 패키지의 스킴 설정도 여기에 저장된다. 공유가 필요한 스킴은 앱 프로젝트 쪽에 둔다.

## GitHub Actions
- `macos` 러너에서 `xcode-select`(또는 setup-xcode 액션)로 **Xcode 버전을 고정**한다. 러너 이미지에 필요한 iOS SDK가 있는지 확인한다.
- 단계:
  1. SPM 캐시 복원
  2. `swift test`로 Domain과 Data 테스트 (빠름)
  3. `xcodebuild test -scheme Moningseutendeu -destination 'platform=iOS Simulator,name=<고정 기기>,OS=<고정 버전>' -enableCodeCoverage YES -resultBundlePath TestResults.xcresult`
  4. `xcrun xccov view --report --json TestResults.xcresult`로 커버리지를 요약해 PR 코멘트나 Job Summary로 올린다
  5. 실패하면 `.xcresult`와 스냅샷 diff를 아티팩트로 업로드한다
- **CI에는 Secrets.xcconfig가 없다.** `#include?`로 빌드는 되고, 테스트는 키 없이 통과해야 한다. 실제 API를 부르는 테스트는 CI에서 돌리지 않는다 (태그로 분리하거나 로컬 전용).
- 스냅샷 테스트는 로컬 기기와 CI 기기가 다르면 깨진다. 레퍼런스를 CI와 같은 기기와 OS로 기록하거나, CI 전용으로 기록한다. 결정한 내용을 이 문서에 적는다.
- 동시 실행 취소(`concurrency: group`)로 같은 PR의 이전 실행을 취소한다.
- 자동 코드 서명을 끈다 (`CODE_SIGNING_ALLOWED=NO`). 시뮬레이터 테스트에는 서명이 필요 없다.

## OSLog
- `Logger(subsystem: AppConstants.Log.subsystem, category: AppConstants.Log.Category.network)` 형태로 쓴다. 카테고리(`network`, `cache`, `rateLimit`, `location`, `posture`, `widget`, `background`)는 AppConstants에 모은다.
- `print`와 `debugPrint`는 금지다.
- 문자열 보간의 기본 privacy는 **`.private`**이다 (기기 로그에서 `<private>`로 보인다). 디버깅에 필요한 비민감 값만 `\(api, privacy: .public)`으로 연다.
- **API 키, 정확한 좌표, 즐겨찾기 주소는 public으로 남기지 않는다.** URL은 키를 마스킹한 뒤 남긴다.
- 레벨 기준:
  | 레벨 | 쓰는 곳 |
  |---|---|
  | `.debug` | 캐시 적중 여부 |
  | `.info` | API 호출과 소요 시간 |
  | `.notice` | 한도 50%, 80% 도달 |
  | `.error` | 디코딩 실패, 키 오류 |
  | `.fault` | 있을 수 없는 상태 |
- API 소요 시간과 캐시 효율을 보여주려면 `OSSignposter`로 구간을 표시하고 Instruments로 확인한다 (포트폴리오 스크린샷용).
- 로그 확인: Console.app에서 subsystem으로 필터링하거나, `log stream --predicate 'subsystem == "com.jiyong.Moningseutendeu"'`를 쓴다.

## 체크리스트
- [ ] Domain 패키지에 외부 의존성이 없는가
- [ ] `swift test`가 macOS에서 도는가
- [ ] CI가 키 없이 초록불인가
- [ ] 로그에 민감 정보가 public으로 남지 않는가
