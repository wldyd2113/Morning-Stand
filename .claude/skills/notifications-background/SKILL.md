---
name: notifications-background
description: UserNotifications and BackgroundTasks (BGAppRefreshTask) pitfalls for MorningStand — permission timing, 64 pending limit, replacing departure alerts by identifier, umbrella alerts from last-known forecast, time-sensitive entitlement, BGTask registration/scheduling/expiration, SwiftUI .backgroundTask, debugging, and never depending on background execution. Use before implementing notifications or background refresh.
---

# 알림 · 백그라운드 갱신 주의사항

## UserNotifications
- `NotificationScheduler` 프로토콜 뒤에 숨긴다. ViewModel과 UseCase는 UserNotifications를 모른다. 테스트는 Mock으로 "어떤 알림이 언제 예약됐는지"를 검증한다.
- 권한은 사용자가 출발 알림을 켜는 순간에 요청한다. 앱을 처음 켰을 때 요청하지 않는다. 거부 상태도 UI에 보여준다.
- 대기 중인 로컬 알림은 **앱당 64개**까지다. 요일별 루틴 × 여러 알림을 전부 미리 예약하지 말고, **가까운 며칠분만** 예약하고 앱이 실행될 때마다 채운다.
- 출발 알림:
  - 도착 정보는 계속 바뀐다. 같은 `identifier`(`AppConstants.NotificationID`)로 다시 예약하면 **교체**된다. 새로 계산할 때마다 교체한다.
  - 앱이 백그라운드에 있으면 재계산할 기회가 없다. 그래서 알림 문구는 "N분 뒤 버스"처럼 확정적으로 쓰지 말고 **"곧 출발할 시간이에요 · 7:42 기준"**처럼 기준 시각을 넣는다.
  - 예약하는 쪽의 시간 계산은 주입받은 `DateProvider` 기준 순수 함수로 만들어 테스트한다.
- 우산 알림:
  - 아침에 BG 갱신이 된다는 보장이 없다. 전날 밤이나 마지막 실행 시점의 단기예보로 **다음 날 아침 알림을 미리 예약**하고, 새 예보를 받을 때마다 교체하거나 취소한다.
  - 기준(POP, PTY, 시간대)은 PolicyConstants에 둔다.
- `interruptionLevel = .timeSensitive`는 entitlement(Time Sensitive Notifications)가 필요하다. 없으면 무시된다.
- 포그라운드에서도 알림을 보여주려면 `UNUserNotificationCenterDelegate.willPresent`를 구현한다. 스탠드 모드 화면에서는 배너 대신 화면 안에서 강조하는 편이 낫다.
- 알림을 탭했을 때 이동할 곳(딥링크)은 `userInfo`에 넣고 처리한다.

## BackgroundTasks (BGAppRefreshTask)
- **실행 시점과 실행 여부가 보장되지 않는다.**
  - 사용 패턴, 배터리, 저전력 모드에 따라 며칠 동안 안 돌 수도 있다.
  - 핵심 기능(카운트다운, 알림 예약)은 BG 없이도 동작해야 하고, BG는 "출근 전에 캐시와 스냅샷을 미리 채워두면 좋은" 정도로만 쓴다.
- 식별자는 `AppConstants.BackgroundTaskID`에 두고, Info.plist `BGTaskSchedulerPermittedIdentifiers`에 똑같이 등록한다. `UIBackgroundModes`에는 `fetch`를 넣는다.
- SwiftUI에서는 `.backgroundTask(.appRefresh(id)) { await ... }` 수정자를 쓴다.
  - 핸들러 안에서 **다음 요청을 다시 예약**해야 계속 실행된다.
  - `BGTaskScheduler.shared.submit`은 앱이 백그라운드로 갈 때(`scenePhase == .background`)에도 한다.
- `earliestBeginDate`는 "이 시각 이후"라는 힌트일 뿐이다. 출근 시간 30~60분 전으로 잡는다 (PolicyConstants).
- 실행 시간은 약 30초로 짧다. 병렬로 한 번씩만 부르고 폴링하지 않는다. 시간이 다 되면 취소되므로 Task 취소를 존중하고, 부분 결과라도 스냅샷에 저장한다.
- BG에서 한 호출도 RateLimiter에 포함한다.
- BG 작업이 끝나면 스냅샷을 쓰고, 필요하면 `reloadTimelines`와 알림 교체까지 한다.
- 디버그: 기기에서 앱을 백그라운드로 보낸 뒤 LLDB에서
  `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"<id>"]`
  를 실행한다. 시뮬레이터에서는 동작이 제한적이다.

## 체크리스트
- [ ] BG가 한 번도 안 돌아도 앱의 핵심 기능이 동작하는가
- [ ] 대기 알림 수가 64개 한도 안에서 관리되는가
- [ ] 알림 문구가 오래된 정보를 확정값처럼 말하지 않는가
- [ ] BG 식별자가 코드와 Info.plist에서 일치하는가
