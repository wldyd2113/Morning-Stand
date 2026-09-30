---
name: location-kma-grid
description: CoreLocation and coordinate pitfalls for MorningStand — LocationProvider abstraction, when-in-use authorization flow, one-shot location via CLLocationUpdate, reduced accuracy, simulator locations, WGS84→KMA grid (Lambert Conformal Conic) conversion with test vectors, nearest bus stop / air-quality station search, walking-time estimation. Use before touching location, grid conversion, or nearest-station logic.
---

# 위치 · 격자 변환 주의사항

## LocationProvider
- `protocol LocationProvider: Sendable { func currentLocation() async throws(AppError) -> Coordinate }` 형태로 둔다.
  - `Coordinate`는 Domain의 `struct Coordinate: Sendable { latitude, longitude }`다. Domain은 CoreLocation을 모른다.
- 구현(`CoreLocationProvider`)은 `Platform/`에 두고, 테스트와 Preview는 `MockLocationProvider`(고정 좌표)를 쓴다.
- 스탠드 모드에서는 계속 위치를 받을 필요가 없다 (협탁에 고정). **앱 시작이나 모드 진입 시 한 번** 받고 캐시한다. 배터리와 권한 부담이 적다.
- 한 번만 받을 때는 `CLLocationUpdate.liveUpdates()`에서 정확도가 충분한 첫 값을 받고 루프를 끝낸다. 타임아웃(PolicyConstants)을 둔다.
  - `CLLocationManager` 델리게이트 방식을 쓸 경우 매니저는 MainActor에서 만들고 유지해야 한다.
- 즐겨찾기 정류장이 있으면 위치 없이도 동작해야 한다. 위치는 "주변 정류장 찾기"와 "가까운 측정소/격자 결정"에만 쓴다. 집 위치를 한 번 저장하면 이후에는 저장값을 쓴다.

## 권한
- Info.plist에 `NSLocationWhenInUseUsageDescription`을 넣는다 (문구는 기능 설명). Always 권한은 요청하지 않는다.
- 권한은 사용자가 "주변 정류장 찾기"를 누를 때처럼 **의미 있는 시점에** 요청한다. 앱을 켜자마자 요청하지 않는다.
- 거부되거나 제한된 경우: 수동 정류장 검색과 기본 지역(서울시청) 날씨로 대체하고, 설정 앱으로 가는 버튼을 제공한다.
- **대략적 위치(reduced accuracy)**일 때는 오차가 수 km라서 주변 정류장 찾기에 쓸 수 없다. 날씨와 측정소 결정에는 충분하므로 기능별로 다르게 처리한다. 정확한 위치가 필요하면 임시 정확 위치를 요청한다.
- 권한 상태 변화는 AsyncStream으로 노출해서 ViewModel이 반응하게 한다.

## 위경도 → 기상청 격자 변환 (LCC)
- 순수 함수 `KMAGridConverter.toGrid(latitude:longitude:) -> GridPoint(nx, ny)`를 Domain에 둔다. 상수는 기상청 명세 값을 그대로 쓰고, 한곳(`PolicyConstants.KMAGrid` 또는 컨버터 내부 `private enum`)에 둔다.
  | 상수 | 값 |
  |---|---|
  | 지구 반경 RE | 6371.00877 km |
  | 격자 간격 GRID | 5.0 km |
  | 표준위도 SLAT1 / SLAT2 | 30.0 / 60.0 |
  | 기준점 경도 OLON / 위도 OLAT | 126.0 / 38.0 |
  | 기준점 격자 XO / YO | 43 / 136 |
- 결과는 `floor(x + 0.5)`로 반올림한다. `Int(x)`로 자르면 경계에서 1칸씩 틀린다.
- 테스트 벡터 (파라미터화 테스트, 기상청 격자 엑셀 파일과 대조):
  | 위치 | 위경도 | 기대 (nx, ny) |
  |---|---|---|
  | 서울시청 부근 | 37.5665, 126.9780 | 60, 127 |
  | 기준점 | 38.0, 126.0 | 43, 136 |
  - 나머지 벡터(부산, 제주, 경기 외곽 등)는 기상청이 제공하는 격자 좌표 엑셀에서 뽑아 추가한다. 추측한 값을 기대값으로 쓰지 않는다.
- 역변환(격자 → 위경도)은 필요할 때만 구현한다.
- 격자가 바뀌지 않으면 날씨 캐시 키가 같으므로, 조금 이동해도 추가 호출이 생기지 않는다.

## 가까운 정류장 · 측정소
- 서울 주변 정류장 API의 `tmX`/`tmY`는 이름과 달리 WGS84 경도/위도다. 경기 API의 `x`/`y`도 경도/위도다. **x = 경도**라는 점을 Mapper 주석과 테스트로 고정한다.
- 측정소는 목록을 캐시하고 온디바이스에서 하버사인(haversine) 거리로 가장 가까운 곳을 찾는다 (`korean-public-apis` 스킬 참고).
  - 거리 계산 함수는 Domain에 순수 함수로 둔다.
- 가장 가까운 측정소가 결측(`-`)이면 두 번째로 가까운 측정소로 넘어가는 정책을 둘지 결정한다 (거리 한도는 PolicyConstants에 둔다).

## 도보 시간
- 도보 시간 = 직선거리 × 우회 계수 ÷ 보행 속도. 계수와 속도(예: 1.3, 1.2 m/s)는 PolicyConstants에 두고, 사용자가 즐겨찾기별로 직접 설정한 값이 있으면 그것을 우선한다.
- MapKit 도보 경로 계산(`MKDirections`)은 호출 제한과 비용이 있으므로, 즐겨찾기를 등록할 때 한 번만 계산해서 저장하는 방식을 고려한다.

## 시뮬레이터
- Xcode Scheme → Options → Default Location, 또는 GPX 파일로 서울시청과 경기 지역 좌표를 준비한다. GPX 파일은 `Moningseutendeu/Resources/Locations/`에 둔다.

## 체크리스트
- [ ] Domain에 `import CoreLocation`이 없는가
- [ ] 권한 거부, 대략적 위치에서도 앱이 동작하는가
- [ ] 격자 변환 반올림이 `floor(x + 0.5)`인가, 테스트 벡터가 공식 값인가
- [ ] x/y(경도/위도) 순서를 테스트로 고정했는가
