---
name: swiftui-observation
description: SwiftUI + Observation (@Observable) + MVVM pitfalls for MorningStand — ViewModel ownership, @State init side effects, .task cancellation, DisplayModel formatting, dependency injection, previews, SF Symbols, accessibility. Use before writing or reviewing any SwiftUI View or ViewModel.
---

# SwiftUI · Observation · MVVM 주의사항

## ViewModel
- 형태는 `@MainActor @Observable final class XxxViewModel`로 고정한다. `ObservableObject`, `@Published`, `@StateObject`는 쓰지 않는다.
- ViewModel은 **SwiftUI를 import하지 않는다** (`Color`, `Font`, `Image` 금지).
  - 색이나 심볼은 의미 있는 enum으로 넘긴다 (예: `AirQualityLevel.bad`).
  - View가 그 enum을 `DesignTokens`로 바꿔 그린다.
- UIKit(`UIApplication`)도 import하지 않는다. idle timer 같은 것은 Platform 서비스 프로토콜로 주입한다.
- 표시 문자열 포매팅("3분 후", "곧 도착")은 ViewModel이나 Presentation Mapper에서 하고 테스트한다. View는 결과만 그린다.
- 관찰할 필요가 없는 의존성, Task 핸들은 `@ObservationIgnored`로 둔다 (불필요한 뷰 갱신 방지).

## 소유와 생명주기
- 화면이 ViewModel을 소유할 때는 `@State private var viewModel: XxxViewModel`을 쓴다.
- `@State var vm = XxxViewModel(...)`의 초기값 식은 **View가 init될 때마다 다시 평가된다**. 객체는 버려지지만 init 부작용은 매번 일어난다.
  - 따라서 ViewModel `init`에서는 네트워크, 타이머, 알림 등록 같은 부작용을 하지 않는다.
  - 작업 시작은 `.task { await viewModel.start() }`에서 한다.
- 하위 View에는 `let viewModel` 또는 필요한 값만 넘긴다. 바인딩이 필요하면 `@Bindable`을 쓴다.
- 비동기 작업은 `.task` / `.task(id:)`에 둔다. `onAppear { Task { } }`는 취소되지 않으므로 금지.
- `scenePhase`가 바뀔 때(백그라운드 진입) 폴링을 멈추는 처리는 ViewModel의 메서드로 위임한다.

## 의존성 주입
- `App/AppDependencies`가 실제 구현을 조립하고, 화면 루트에서 ViewModel을 만들 때 넘긴다.
- `@Environment`에 넣는 것은 **팩토리/컨테이너** 하나로 제한한다. 개별 Repository를 여기저기 환경으로 뿌리지 않는다.
- UI 테스트나 Preview용 Mock 구성은 `AppDependencies.mock(...)` 같은 이름으로 둔다.

## 레이아웃
- 폼팩터 전환(스탠드/플래닝)은 `PostureProvider` 값에 따라 **상위 컨테이너에서만** 분기하고, 섹션 View는 재사용한다 (`stand-mode` 스킬 참고).
- 스탠드 화면의 1초 단위 갱신은 작은 하위 View(시계, 카운트다운)에만 `TimelineView`를 둔다. 트리 전체가 다시 그려지지 않게 한다.
- 숫자가 바뀌는 텍스트에는 `.monospacedDigit()`과 `.contentTransition(.numericText())`를 써서 글자 폭이 흔들리지 않게 한다.
- 크기, 간격, 색, 애니메이션 시간은 전부 `DesignTokens`에서 가져온다. `.padding(12)` 같은 리터럴은 금지.

## 섹션 상태 표시
- `SectionState`의 모든 case를 그리는 공용 `SectionStateView`를 만들어 재사용한다.
  - `.stale`: 값을 보여주고 "N분 전 기준" 배지를 붙인다.
  - `.failed`: 해당 섹션에만 오류와 재시도 버튼을 보여준다.
- 로딩 중에도 이전 값이 있으면 그대로 보여준다 (깜빡임 방지).

## SF Symbols
- 심볼 이름 문자열은 `DesignTokens.Symbol`에 모은다 (하드코딩 금지 규칙).
- 날씨 코드(SKY, PTY) → 심볼 매핑은 Presentation 계층에 둔다. Domain은 `WeatherCondition` enum만 안다.
- 쓰려는 심볼이 배포 타깃 iOS 버전에 있는지 SF Symbols 앱에서 확인한다.
- 다색 날씨 아이콘은 `.symbolRenderingMode(.multicolor)`로 그린다. 야간 테마에서는 `.hierarchical`로 바꿔 채도를 낮출지 검토한다.

## 접근성·현지화
- 사용자 문구는 String Catalog(`Localizable.xcstrings`)로 관리한다.
- 카운트다운 숫자에는 `accessibilityLabel`로 "3분 후 출발"처럼 읽히는 문장을 준다.
- Dynamic Type 큰 글꼴에서 스탠드 화면이 넘치지 않는지 스냅샷으로 확인한다.
- Reduce Motion이 켜져 있으면 번인 방지 이동과 숫자 전환 애니메이션을 줄인다.
- UI 테스트용 `accessibilityIdentifier`는 `AppConstants.AccessibilityID`에서 가져온다.

## Preview
- 모든 화면에 `#Preview`를 두고, Mock 의존성으로 loaded / stale / failed 상태를 각각 보여준다.
- Preview에서 실제 네트워크를 호출하지 않는다.

## 체크리스트
- [ ] View 안에 `if` 분기로 비즈니스 판단(출발 가능 여부, 등급 계산)이 없는가
- [ ] ViewModel이 SwiftUI, UIKit, Alamofire, SwiftData를 import하지 않는가
- [ ] 비동기 시작점이 `.task`인가
- [ ] 리터럴 숫자, 색, 심볼 이름이 없는가
