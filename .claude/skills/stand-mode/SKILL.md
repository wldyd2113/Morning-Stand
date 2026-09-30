---
name: stand-mode
description: Stand-mode (half-folded foldable iPhone) pitfalls for MorningStand — PostureProvider abstraction and mock, heuristic posture detection until an official API is confirmed, stand/planning layout switching, isIdleTimerDisabled lifecycle, TimelineView cadence, OLED burn-in offset animation, time-based night theme, battery/low power considerations. Use before implementing or reviewing the stand/planning screens or anything posture-related.
---

# 스탠드 모드 주의사항

## PostureProvider
- `enum DevicePosture: Sendable { case closed, halfOpened, flat }`로 정의한다.
  - `protocol PostureProvider: Sendable { var current: DevicePosture { get }; var updates: AsyncStream<DevicePosture> { get } }`
- **폴더블 iPhone의 자세(힌지 각도)를 알려주는 공개 API를 아직 확인하지 못했다.** 구현은 두 단계로 나눈다.
  1. `HeuristicPostureProvider`: 윈도우 크기와 비율, 방향(가로/세로)으로 추정한다. 예를 들어 안쪽 큰 화면이 가로로 길고 세로 크기가 특정 비율 이하이면 `halfOpened` 후보로 본다. 기준값은 PolicyConstants에 둔다.
  2. `SystemPostureProvider`: 공식 API가 확인되면 교체한다. 이 파일에 TODO와 확인 날짜를 남긴다.
- `MockPostureProvider`: 시뮬레이터와 테스트용이다. DEBUG 메뉴(또는 launch argument `-posture halfOpened`)로 전환한다. 스냅샷 테스트도 이것으로 폼팩터별 화면을 만든다.
- 자세 판정이 흔들리지 않게 짧은 debounce를 둔다 (값은 PolicyConstants). 접는 도중에 레이아웃이 여러 번 바뀌면 안 된다.
- 판정이 틀릴 수 있으므로 **사용자가 수동으로 스탠드 모드를 켜고 끌 수 있는 토글**을 둔다.

## 레이아웃 전환
- 루트 컨테이너가 posture를 보고 분기한다.
  - `halfOpened` → `StandView`(위: 시계·날씨·미세먼지 / 아래: 카운트다운·도착)
  - `flat` → `PlanningView`
- 위아래 영역은 힌지 위치를 기준으로 나눈다. 힌지 영역에 중요한 숫자가 걸치지 않게 여백을 둔다 (값은 DesignTokens에 둔다).
- 섹션 View(날씨 카드, 도착 행 등)는 두 모드에서 재사용하고, 크기만 바뀐다.
- 분기 로직("지금 스탠드 모드인가, 폴링해야 하나")은 ViewModel에서 결정하고 테스트한다. View는 결과만 따른다.

## 화면 꺼짐 방지 (isIdleTimerDisabled)
- `UIApplication.shared.isIdleTimerDisabled`는 UIKit이므로 `IdleTimerController` 프로토콜로 감싸 Platform에 둔다. ViewModel은 프로토콜만 안다.
- **스탠드 화면에서만 켠다.** 반드시 아래 경우에 끈다 (짝을 맞춘다).
  - 스탠드 화면의 `onDisappear`
  - `scenePhase`가 `.background` / `.inactive`로 바뀔 때
  - posture가 `halfOpened`가 아니게 될 때
- 켜기/끄기 로직을 여러 곳에 흩어두지 말고, 한 곳에서 `(isStandMode && scenePhase == .active && userEnabled)`로 계산해 **상태에서 파생**시킨다. 파생 함수는 테스트한다.
- 배터리 옵션: 충전 중일 때만 화면을 켜두는 설정을 검토한다 (`UIDevice.batteryState`, 역시 프로토콜 뒤에 둔다). 저전력 모드에서는 갱신 빈도와 애니메이션을 줄인다.

## TimelineView
- 시계: 초를 보여주지 않으면 `.everyMinute`을 쓴다. 초가 필요할 때만 `.periodic(from:by: 1)`을 쓴다.
- 카운트다운: `Text(timerInterval:)`이나 `Text(date, style: .timer)`로 시스템이 그리게 하면 가장 싸다. 직접 계산이 필요하면 TimelineView의 `context.date`를 ViewModel의 순수 함수에 넘겨 계산한다.
- TimelineView는 작은 하위 View에만 둔다. 부모 전체를 감싸면 매초 전체가 다시 그려진다.
- 화면 안에서 "N분 뒤 출발"이 0이 되면 다음 차량으로 넘어가는 전환은 ViewModel이 도메인 규칙으로 처리한다.

## 번인 방지 (OLED)
- 고정 요소(시계, 큰 숫자)를 **몇 분마다 수 pt씩** 천천히 이동시킨다. 주기, 최대 이동량, 애니메이션 시간은 DesignTokens/PolicyConstants에 둔다.
- 오프셋 값은 주입받은 시각으로 결정적으로 계산하는 순수 함수(`burnInOffset(at: Date) -> CGSize`)로 만든다. 그래야 테스트와 스냅샷이 흔들리지 않는다. 스냅샷 테스트에서는 오프셋 0으로 고정한다.
- 순백색 큰 면적과 고정 테두리를 피한다. 야간에는 밝기가 낮은 색을 쓴다.
- Reduce Motion이 켜져 있으면 이동 대신 매우 느린 페이드나 투명도 변화로 대체한다.

## 야간 테마
- 시간대(예: 22:00~06:00, PolicyConstants)에 따라 `DisplayTheme.night`으로 바꾼다. 판정은 주입받은 `DateProvider` 기준 순수 함수로 하고, 경계 시각을 테스트한다.
- 야간 테마는 어둡고 붉은 계열에 대비가 낮은 토큰 세트로 `DesignTokens`에 둔다. 시스템 다크 모드와는 별개로 동작한다.
- `UIScreen.brightness`를 바꾸는 것은 피한다. 바꾼다면 화면을 떠날 때 원래 값으로 복원해야 한다.

## 체크리스트
- [ ] idle timer가 켜지는 경로가 하나이고, 끄는 경로가 모든 이탈 상황을 덮는가
- [ ] 시뮬레이터에서 Mock으로 세 가지 posture를 모두 확인할 수 있는가
- [ ] TimelineView 범위가 최소한인가
- [ ] 번인 오프셋과 야간 테마 판정이 순수 함수이고 테스트가 있는가
