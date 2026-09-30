---
name: swiftdata-persistence
description: SwiftData and App Group UserDefaults pitfalls for MorningStand — ModelContext/@Model not Sendable, @ModelActor stores, mapping to domain structs, VersionedSchema migrations, in-memory test containers, no @Query in Views, and the widget snapshot contract in App Group UserDefaults. Use before adding models, stores, favorites/routines/history persistence, or snapshot sharing with widgets.
---

# SwiftData · App Group 저장 주의사항

## 무엇을 어디에 저장하나
| 데이터 | 저장소 |
|---|---|
| 즐겨찾기 정류장·역·경로, 요일별 루틴, 사용 기록 | SwiftData |
| 위젯·Live Activity가 읽을 최신 대시보드 스냅샷 | App Group `UserDefaults` (Codable JSON) |
| RateLimiter 카운터, 간단한 설정 | App Group `UserDefaults` |
| API 응답 캐시 | CacheStore (Caches 디렉터리), SwiftData에 넣지 않는다 |

## SwiftData
- `ModelContext`와 `@Model` 인스턴스는 **Sendable이 아니다**. actor나 Task 경계를 넘기면 안 된다.
  - 백그라운드 작업은 `@ModelActor actor FavoriteStore`에서 한다.
  - 경계를 넘길 때는 **도메인 struct**나 `PersistentIdentifier`로 넘긴다.
- `@Model` 타입은 Data 계층(`Persistence/Models`)에만 둔다. Domain Entity(`Favorite`)와 별도로 두고 Mapper로 변환한다. Domain은 SwiftData를 import하지 않는다.
- View에서 `@Query`를 쓰지 않는다 (MVVM 규칙). ViewModel → UseCase → Repository → Store 경로로 읽는다.
  - 변경을 알아야 하면 Store가 저장한 뒤 AsyncStream으로 알려주거나, ViewModel이 저장 후 다시 불러온다.
- `ModelContainer`는 앱 전체에서 하나를 만들어 `AppDependencies`가 소유한다.
  - `@ModelActor` Store는 그 container로 만든다. 같은 container에서 Store를 여러 개 만들면 컨텍스트끼리 변경 사항이 즉시 공유되지 않을 수 있다.
- 처음부터 `VersionedSchema`(`SchemaV1`)와 `SchemaMigrationPlan`을 만든다. 포트폴리오 기간 중에도 모델이 바뀌므로, 나중에 붙이면 기존 데이터가 깨진다.
- 중복 방지는 `@Attribute(.unique)` 또는 `#Unique`로 하되, 서울/경기 정류장처럼 **복합 키**(provider + stopID)가 필요한 곳에 주의한다.
- `save()`는 명시적으로 호출하고 에러를 처리한다. 자동 저장에 의존하지 않는다.
- 관계(`@Relationship`)의 삭제 규칙(`.cascade`/`.nullify`)을 명시한다 (루틴 삭제 시 루틴 항목도 삭제).
- enum 속성은 `Codable` raw value로 저장한다. enum case 이름을 바꾸면 마이그레이션이 필요하다.
- 테스트: `ModelConfiguration(isStoredInMemoryOnly: true)`로 만든 container를 테스트마다 새로 만든다. Swift Testing은 병렬로 돌기 때문에 container를 공유하면 테스트끼리 간섭한다.
- 위젯에서 SwiftData를 열지 않는다. 위젯은 스냅샷만 읽는다.

## App Group UserDefaults 스냅샷
- `UserDefaults(suiteName: AppConstants.appGroupID)`를 쓴다. 앱과 위젯 **두 타깃 모두**에 App Group entitlement가 있어야 하고, 없으면 조용히 nil이나 빈 값이 된다.
- 스냅샷 타입은 `SharedAppGroup/DashboardSnapshot.swift`에 두고 **양쪽 타깃 멤버십**으로 공유한다.
  - `Codable & Sendable`
  - `schemaVersion` 필드
  - `generatedAt`(위젯의 "N분 전 기준" 표시용)
  - 섹션별 값과 상태
- 크기는 작게 유지한다 (수 KB). 도착 목록은 즐겨찾기 상위 몇 개만 넣는다.
- "N분 뒤 출발"은 스냅샷에 **절대 시각**(`departAt: Date`)으로 저장한다. 위젯이 현재 시각 기준으로 다시 계산하거나 `Text(timerInterval:)`로 표시한다. 남은 분(상대값)을 저장하면 금방 틀려진다.
- 스냅샷을 쓴 뒤에 `WidgetCenter.shared.reloadTimelines(ofKind:)`를 호출한다. 이 호출도 예산을 소모하므로 **값이 의미 있게 바뀌었을 때만** 한다 (`widgetkit-liveactivity` 스킬 참고).
- 디코딩에 실패하면(스키마 불일치) 위젯은 placeholder를 보여주고 크래시하지 않는다.
- 키 문자열은 `AppConstants.UserDefaultsKey`에 둔다.

## 체크리스트
- [ ] `@Model`이나 `ModelContext`가 actor/Task 경계를 넘지 않는가
- [ ] Domain과 Presentation에 `import SwiftData`가 없는가
- [ ] 스키마 버전과 마이그레이션 플랜이 있는가
- [ ] 스냅샷이 상대 시간이 아닌 절대 시각을 담는가
- [ ] 두 타깃에 App Group entitlement가 있는가
