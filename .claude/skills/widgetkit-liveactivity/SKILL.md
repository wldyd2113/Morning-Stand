---
name: widgetkit-liveactivity
description: WidgetKit, ActivityKit (Live Activity / Dynamic Island), App Intents, and App Groups pitfalls for MorningStand — snapshot-only widgets, reload budget, self-updating timer text, 8-hour activity limit, 4KB ContentState, no push server, starting activities, interactive widget refresh intent without network, App Shortcuts, shared target membership. Use before implementing or reviewing widgets, Live Activities, App Intents, or anything in the widget extension.
---

# WidgetKit · Live Activity · App Intents 주의사항

## 공통: App Group과 타깃 구성
- 앱과 위젯 익스텐션 **양쪽에** 같은 App Group(`AppConstants.appGroupID`)을 켠다. 한쪽만 켜면 오류 없이 빈 값만 읽힌다.
- 두 타깃이 공유하는 코드는 `SharedAppGroup/`에 두고, 양쪽 타깃 멤버십을 켠다.
  - `DashboardSnapshot`
  - `DepartureActivityAttributes`
  - 위젯에서도 쓰는 App Intent
  - 공용 DesignTokens 일부
- 위젯 익스텐션에 Alamofire, SwiftData, Data 패키지를 링크하지 않는다 (메모리, 용량, 규칙 위반).
- 위젯 익스텐션의 메모리 한도는 수십 MB 수준으로 작다. 큰 이미지나 목록을 스냅샷에 넣지 않는다.

## WidgetKit
- **위젯은 네트워크를 호출하지 않는다.** `TimelineProvider`는 App Group 스냅샷만 읽어 entry를 만든다.
- 갱신 예산은 하루에 대략 40~70회 수준이다 (시스템이 조절하며 보장되지 않는다).
  - 앱이 스냅샷을 쓴 뒤 `reloadTimelines(ofKind:)`를 호출하는 것은 **값이 의미 있게 바뀌었을 때만** 한다 (예: 출발 시각이 1분 이상 바뀜, 섹션 상태가 바뀜).
  - 폴링할 때마다 호출하지 않는다.
- 카운트다운은 entry를 1분마다 만드는 대신 `Text(departAt, style: .timer)`나 `Text(timerInterval:countsDown:)`를 쓴다. 시스템이 알아서 줄어드는 숫자를 그린다.
  - 출발 시각이 지나면 음수가 되지 않게, 타임라인에 "출발 시각" 시점의 entry를 하나 더 넣어 "놓침 / 다음 차" 상태로 바꾼다.
- 정책은 `.after(다음 의미 있는 시각)` 또는 `.never`로 둔다 (앱이 reload를 호출하므로). 짧은 간격의 `.atEnd` 반복은 예산만 쓴다.
- 스냅샷의 `generatedAt`으로 "N분 전 기준"을 표시한다. 오래되면(PolicyConstants 기준) 흐리게 처리하거나 "앱을 열어 갱신"을 안내한다.
- 모든 위젯 뷰에 `.containerBackground(for: .widget)`를 지정한다. 잠금 화면(accessory) 계열은 단색·vibrant 렌더링을 고려하고, `widgetRenderingMode`와 틴트 모드를 확인한다.
- `placeholder`는 즉시 반환하는 가짜 데이터, `getSnapshot`은 갤러리용 샘플, `getTimeline`은 실제 스냅샷을 쓴다.
- 위젯 뷰도 스냅샷 테스트한다 (family별).

## ActivityKit (Live Activity, Dynamic Island)
- Info.plist에 `NSSupportsLiveActivities = YES`를 넣는다.
- 제한:
  - 활성 상태는 **최대 8시간**, 종료 후 잠금 화면에 최대 4시간 더 남는다.
  - `ContentState`는 **4KB 이하**다.
  - 업데이트 빈도는 시스템이 제한한다.
- **서버가 없으므로 푸시로 업데이트할 수 없다.**
  - 앱이 포그라운드이거나 잠깐 백그라운드 실행 중일 때만 업데이트된다.
  - 그래서 ContentState에는 절대 시각(`departAt`, `arrivalAt`)을 넣고 뷰에서 `Text(timerInterval:)`로 카운트다운한다. 앱이 멈춰도 숫자는 줄어든다.
  - `staleDate`를 출발 시각 근처로 설정해서, 오래된 정보가 "갱신 필요"로 표시되게 한다.
- 시작:
  - `Activity.request`는 앱이 **포그라운드일 때** 호출한다 (예: 스탠드 모드에서 "출근 시작"을 누를 때, 또는 App Intent `LiveActivityIntent`로 시작).
  - 사용자가 Live Activity를 꺼 두었을 수 있으므로 `ActivityAuthorizationInfo().areActivitiesEnabled`를 확인한다.
- 종료: 출발 시각이 지나거나 사용자가 출근 모드를 끄면 `end(_:dismissalPolicy:)`를 호출한다. 앱이 다시 실행될 때 남아 있는 `Activity.activities`를 정리한다 (중복 방지).
- Dynamic Island 레이아웃 **compact leading/trailing, minimal, expanded**를 모두 구현한다. minimal은 아이콘과 분 숫자 정도만 둔다.
- 스탠드 모드 화면과 Live Activity가 같은 도메인 값을 보여주도록 `DepartureActivityAttributes`는 Presentation의 DisplayModel에서 만든다.

## App Intents
- "출근 모드 시작" 단축어는 `AppShortcutsProvider`로 제공한다. 문구(phrases)에는 반드시 `\(.applicationName)`이 들어가야 한다.
- 위젯과 앱 양쪽에서 쓰는 Intent는 `SharedAppGroup/`에 두고 두 타깃 멤버십을 켠다 (또는 공유 프레임워크 사용).
- Intent의 `perform()`은 async이고, 파라미터 타입은 Sendable이어야 한다. UI를 만지는 Intent는 `@MainActor`로 표시한다.
- **위젯 새로고침 버튼 충돌 주의**: 인터랙티브 위젯의 `Button(intent:)`은 **위젯 프로세스에서** `perform()`을 실행한다. 그런데 "위젯은 네트워크 금지" 규칙이 있으므로 다음 중 하나를 고른다.
  1. (기본) 스냅샷을 기준으로 현재 시각으로 다시 계산하고 `reloadTimelines`만 한다. 카운트다운과 "놓침 → 다음 차" 전환만 반영된다.
  2. 앱을 열어서 갱신한다 (`openAppWhenRun` 또는 앱 열기 모드).
  - 어떤 방식을 골랐는지 이 문서에 기록한다. 위젯 안에 APIClient를 넣지 않는다.
- Intent에서 한도가 있는 API를 부르게 되면 RateLimiter를 반드시 거친다 (앱 프로세스에서 실행되는 경우에 한해).

## 체크리스트
- [ ] 위젯 타깃에 네트워크, SwiftData, Alamofire 의존성이 없는가
- [ ] reloadTimelines 호출이 변화가 있을 때만 일어나는가
- [ ] 카운트다운이 시스템 타이머 텍스트로 그려지는가
- [ ] Live Activity의 시작/종료/중복 정리/staleDate가 있는가
- [ ] App Group이 두 타깃 모두에 켜져 있는가
