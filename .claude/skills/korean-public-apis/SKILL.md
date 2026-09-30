---
name: korean-public-apis
description: Quirks of the Korean public APIs MorningStand uses — Seoul bus arrival/station (XML, 1,000/day), Gyeonggi bus, Seoul subway realtime (recptnDt correction, arvlMsg), KMA short-term forecast (grid X/Y, base_time rules, category codes, missing values), AirKorea (station lookup, "-" values, grades). Use before implementing or debugging any DTO, mapper, parser, or request parameters for these APIs.
---

# 공공 API별 주의사항

> 필드명, 코드값은 명세서 기준으로 정리했다. **구현 전에 실제 응답으로 한 번 확인하고 fixture로 고정한다** (CLAUDE.md 절차 G). 명세와 다르면 이 문서를 고친다.

## 공통 (공공데이터포털)
- 키 하나로 승인받은 모든 서비스를 호출할 수 있다. 다만 **서비스마다 활용 신청이 따로** 필요하고, 한도도 서비스별로 따로 센다.
- 활용 신청 직후에는 키가 동기화되는 데 시간이 걸린다 (보통 1시간 이상). 그동안 키 오류가 나는 것은 정상이다.
- 에러가 HTTP 200으로 오는 경우가 많다. 본문의 `resultCode`/`returnReasonCode`/`headerCd`를 반드시 확인한다.
- 한도 초과는 보통 `LIMITED_NUMBER_OF_SERVICE_REQUESTS_EXCEEDS_ERROR`(22) 계열로 온다 → `.quotaExceeded`로 매핑하고 **그날은 해당 API를 멈춘다**.
- 운영계정으로 전환하면 한도가 늘어나지만, 전환 여부와 상관없이 RateLimiter 설계는 유지한다.

## 서울 버스 도착정보 / 정류소정보 (XML)
- **일일 1,000건**. 예산 예시: 정류장 1곳을 60초마다 조회하면 출근 2시간에 120건. 즐겨찾기가 3곳이면 360건.
  - 여기에 플래닝 모드와 BG 갱신까지 더해 **총량을 PolicyConstants에 적어 두고** RateLimiter가 강제한다.
- 정류장 기준 조회(`arsId`, 5자리 정류소 번호)를 쓰면 한 번 호출로 그 정류장의 모든 노선을 받는다. 노선마다 따로 호출하는 것보다 한도 면에서 유리하다.
- 응답은 `ServiceResult > msgHeader(headerCd, headerMsg) > msgBody > itemList*` 구조다.
  - `headerCd`가 `0`이면 정상이다. 결과 없음이나 키 오류는 다른 코드로 오므로 코드표를 fixture로 확인한다.
- 도착 메시지 `arrmsg1`/`arrmsg2`는 다음과 같이 파싱한다 (Mapper, 파라미터화 테스트 필수).
  | 원문 예시 | 도메인 |
  |---|---|
  | `3분12초후[2번째 전]` | `.arriving(seconds: 192, stopsAway: 2)` |
  | `58초후[1번째 전]` | `.arriving(seconds: 58, stopsAway: 1)` |
  | `곧 도착` | `.imminent` |
  | `운행종료` | `.serviceEnded` |
  | `출발대기` | `.waitingDeparture` |
  | `회차지 출발`, 기타 | `.unknown(raw)` → 원문 그대로 표시 |
  - 정규식은 `Regex` 리터럴로 쓰고, 공백 차이(`3분 12초후`)도 허용한다.
- 초 단위 숫자 필드(예: `traTime1`)가 있으면 그 값을 우선 쓰고, 없거나 0이면 `arrmsg`를 파싱한다. 둘이 다를 때 어느 쪽을 믿을지 fixture로 확인해 여기에 적는다.
- 정류소정보(좌표 기반 주변 정류장)는 파라미터 이름이 `tmX`/`tmY`인데 **실제로는 WGS84 경도/위도**다. 이름만 보고 TM 좌표로 변환하지 않는다. 반경 단위는 m다.

## 경기도 버스 도착정보 / 정류소 (JSON·XML)
- 정류장 ID는 `stationId`(내부 ID)다. 서울의 `arsId`와 체계가 다르다.
  - 도메인에서는 `StopID(provider: .seoul | .gyeonggi, value:)`로 구분해서 섞이지 않게 한다.
- 도착 시간은 **분 단위**(`predictTime1`)이고, `locationNo1`은 몇 정거장 전인지다. 서울처럼 초 단위가 아니라는 점을 "N분 뒤 출발" 계산에서 반올림 정책으로 명시한다.
- 응답 형식은 요청 파라미터로 JSON을 고를 수 있다 (파라미터 이름은 명세 확인). 결과 없음이 에러 코드로 오는지 fixture로 확인한다.
- 서울과 경기 경계 정류장은 양쪽 API에 모두 있을 수 있다. 즐겨찾기를 저장할 때 provider를 함께 저장한다.

## 서울 지하철 실시간 도착 (서울 열린데이터광장, JSON)
- URL: `.../api/subway/{KEY}/json/realtimeStationArrival/{start}/{end}/{역명}`. **키가 경로에 들어가고**, 역명은 경로 세그먼트로 퍼센트 인코딩한다.
- 역명에는 "역"을 붙이지 않는다 (`서울역` ✗ → `서울` ✓). 예외 역명은 fixture로 확인한다.
- 정상은 `errorMessage.code == "INFO-000"`, 데이터 없음은 `"INFO-200"`(빈 배열로 처리)이다. 그 외(`ERROR-xxx`)는 에러로 처리한다.
- 주요 필드
  | 필드 | 의미 |
  |---|---|
  | `barvlDt` | 도착까지 남은 초 (**노선에 따라 0으로 오는 경우가 있다**) |
  | `recptnDt` | 데이터 생성 시각 `"yyyy-MM-dd HH:mm:ss"` (소수점이 붙기도 함), KST |
  | `arvlMsg2` | "전역 도착", "[3]번째 전역 (OO)", "OO 도착" 같은 문자열 |
  | `arvlMsg3` | 현재 열차 위치 역명 |
  | `arvlCd` | 0 진입, 1 도착, 2 출발, 3 전역출발, 4 전역진입, 5 전역도착, 99 운행중 |
  | `updnLine`, `trainLineNm`, `subwayId` | 상/하행(내/외선), 행선지, 호선 |
- **시간 보정**: `남은 초 = barvlDt − (now − recptnDt)`, 0 미만이면 0. `recptnDt`는 `Asia/Seoul`로 파싱하고, 파싱에 실패하면 보정 없이 쓰되 로그를 남긴다.
- `barvlDt == 0`이면 `arvlCd`와 `arvlMsg2`로 대략의 상태만 표시하고 "N분 뒤 출발"은 계산하지 않는다 (추정값을 확정값처럼 보여주지 않기).
- 한 역에 여러 호선과 방향이 섞여 온다. 즐겨찾기에는 `subwayId + updnLine`까지 저장해서 필터링한다.

## 기상청 단기예보 (JSON, 격자 좌표)
- 요청 좌표는 위경도가 아닌 **`nx`, `ny` 격자**다 (변환은 `location-kma-grid` 스킬 참고). `dataType=JSON`을 반드시 준다.
- 서비스별 `base_time` 규칙은 아래와 같다. 계산 함수는 순수 함수로 만들어 경계 시각을 파라미터화 테스트한다.
  | 서비스 | 발표 | 호출 가능 시점(대략) | base_time |
  |---|---|---|---|
  | 초단기실황 `getUltraSrtNcst` | 매시 정각 | 매시 40분 이후 | `HH00` (40분 전이면 이전 시각) |
  | 초단기예보 `getUltraSrtFcst` | 매시 30분 | 매시 45분 이후 | `HH30` (45분 전이면 이전 시각) |
  | 단기예보 `getVilageFcst` | 02·05·08·11·14·17·20·23시 | 발표 후 10분 이후 | 가장 최근 발표 시각 (**02시 10분 전이면 전날 23시**) |
- 자정 전후로 날짜가 넘어가는 경우와 전날 23시 발표를 쓰는 경우를 반드시 테스트한다.
- 카테고리 코드: `T1H`/`TMP` 기온, `SKY` 하늘(1 맑음, 3 구름많음, 4 흐림), `PTY` 강수형태(0 없음, 1 비, 2 비/눈, 3 눈, 5 빗방울, 6 빗방울눈날림, 7 눈날림), `POP` 강수확률, `RN1`/`PCP` 강수량, `REH` 습도, `WSD` 풍속
- 강수량은 문자열로 온다: `"강수없음"`, `"1mm 미만"`, `"1.0mm"`, `"30.0~50.0mm"`, `"50.0mm 이상"`. 범위나 이상 값은 enum으로 모델링한다.
- `+900` 이상, `-900` 이하 값은 **결측**이다. 0으로 바꾸지 말고 nil로 둔다.
- 단기예보는 항목이 많아서 `numOfRows`를 충분히 크게 준다 (값은 PolicyConstants에 둔다). 안 그러면 페이지가 잘려 오늘 예보가 빠진다.
- 우산 알림에는 오늘 출근~퇴근 시간대의 `POP`와 `PTY`를 쓴다. 이 기준값도 PolicyConstants에 둔다.

## 에어코리아 (JSON)
- 측정소별 실시간 측정 조회는 `stationName`(측정소 이름)으로 요청한다. `returnType=json`, `dataTerm`, `ver` 파라미터를 명세대로 준다.
- 값이 `"-"`나 빈 문자열이면 결측이다 (점검, 통신장애). `pm10Flag`/`pm25Flag`에 사유가 온다. 결측이면 등급을 계산하지 않고 "측정 중단"으로 표시한다.
- 등급 `pm10Grade`/`pm25Grade`는 1 좋음, 2 보통, 3 나쁨, 4 매우나쁨이다. 등급이 비어 있고 수치만 오면 수치로 등급을 계산하는데, 기준표는 PolicyConstants에 둔다.
- `dataTime`은 `"yyyy-MM-dd HH:mm"`이고 **`24:00`이 올 수 있다** (다음날 00:00으로 처리). 이 경우를 테스트로 고정한다.
- 가까운 측정소 찾기:
  - 근접측정소 API는 **TM 좌표**를 요구해서 WGS84 변환이 번거롭다.
  - 추천하는 방법은 측정소 목록(측정소정보 서비스)을 한 번 받아 길게 캐시하고(예: 7일), 온디바이스에서 가장 가까운 곳을 찾는 것이다.
  - 목록의 좌표 필드(`dmX`/`dmY`)는 **어느 쪽이 위도인지 헷갈리므로** fixture로 확인해서 Mapper에 주석으로 남긴다.
- 측정값은 매시 갱신되고 몇 분 늦게 반영된다. TTL은 1시간 이내로 둔다.

## 체크리스트
- [ ] 결과 없음을 에러가 아니라 빈 결과로 처리하는가
- [ ] 결측값(`-`, `""`, ±900)을 0으로 바꾸지 않았는가
- [ ] 시간 문자열을 KST로 파싱하는가 (`24:00`, 소수점 초 포함)
- [ ] 기상청 base_time 경계(자정, 02시 이전, 40/45분)를 테스트하는가
- [ ] 서울과 경기 정류장 ID를 provider로 구분하는가
