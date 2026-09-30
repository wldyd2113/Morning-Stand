---
name: secrets-xcconfig
description: API key handling for MorningStand — xcconfig include chain, `//` comment trap, Info.plist injection, SecretsReader, Decoding vs Encoding service key, .gitignore verification, CI without secrets, and the limits of client-side key secrecy. Use before touching API keys, xcconfig files, Info.plist build variables, or .gitignore.
---

# API 키 · xcconfig 주의사항

## 주입 경로
```
Config/Secrets.xcconfig (커밋 X)
   ↑ #include? "Secrets.xcconfig"
Config/Base.xcconfig (커밋 O) ── 타깃 Build Configuration에 연결 (Debug/Release)
   ↓ $(DATA_GO_KR_SERVICE_KEY)
Info.plist 항목 DATA_GO_KR_SERVICE_KEY
   ↓ Bundle.main.object(forInfoDictionaryKey:)
SecretsReader (App 타깃) → AppDependencies → APIClient 생성자에 전달
```
- `#include?`(물음표 포함)를 쓰면 파일이 없어도 빌드가 된다. CI나 새로 클론한 환경에서도 빌드와 테스트가 돌아야 하므로 반드시 물음표를 붙인다.
- 테스트는 **실제 키 없이** 통과해야 한다. 네트워크 테스트는 Mock APIClient와 fixture로 한다.
- Xcode 프로젝트에서 타깃의 Build Configuration에 `Base.xcconfig`를 지정한다. `Secrets.xcconfig`를 직접 지정하지 않는다.
- 위젯 익스텐션은 네트워크를 쓰지 않으므로 키가 필요 없다. 키를 위젯 Info.plist에 넣지 않는다.

## xcconfig 함정
- `//`는 **주석**이다. `https://...`를 넣으면 뒷부분이 잘린다. URL은 xcconfig에 넣지 말고 `APIConstants`에 둔다.
- 값에 공백이나 따옴표를 넣지 않는다. 따옴표도 값의 일부가 된다.
- 공공데이터포털은 **Decoding 키**를 넣는다 (Alamofire가 인코딩한다). 키에 `+`, `/`, `=`가 있어도 xcconfig에서는 문제없다.
- xcconfig를 바꾼 뒤 Info.plist 값이 갱신되지 않으면 Clean Build Folder를 한다.

## SecretsReader
- `enum SecretsReader { static var dataGoKrServiceKey: String { ... } }` 형태로 둔다. 키 이름 문자열은 `AppConstants.InfoPlistKey`에 둔다.
- 값이 비어 있거나 `$(`로 시작하면(치환 실패) DEBUG에서 `assertionFailure`와 명확한 로그를 남긴다. Release에서는 해당 API 섹션을 `.failed(.apiKeyMissing)`로 둔다.
- Repository나 Data 패키지는 `Bundle.main`을 읽지 않는다. 키는 생성자로 주입받는다 (테스트 용이).

## .gitignore
- 현재 `.gitignore`는 `*.xcconfig`(단, `!Sample.xcconfig`)라서 `Base.xcconfig`도 무시된다. 아래처럼 좁히는 것을 권장한다.
  ```
  Config/Secrets.xcconfig
  ```
- `*Key.swift`, `*Keys.swift`, `*Secret(s).swift`, `*APIKey*.swift` 패턴도 무시 대상이다. 키를 **읽는 코드**는 커밋해야 하므로 이 패턴을 피해 `SecretsReader.swift`로 이름 짓는다.
  - `AppSecrets.swift`, `APIKeys.swift` 같은 이름은 **조용히 커밋에서 빠진다**. 새 파일을 만든 뒤에는 `git check-ignore -v <파일>`로 확인한다.
- 확인 명령:
  - `git check-ignore -v Config/Secrets.xcconfig` (무시되어야 함)
  - `git check-ignore -v Config/Base.xcconfig` (무시되면 안 됨)
- 실수로 키를 커밋했으면 히스토리에서 지우는 것보다 **포털에서 키를 재발급하는 것**이 먼저다.

## 한계 (포트폴리오 README에도 적을 것)
- 서버가 없으므로 키는 앱 바이너리 안에 들어간다. 추출이 가능하다.
- xcconfig 분리의 목적은 **Git 유출 방지**이지 역공학 방어가 아니다. 공공 무료 API라 위험은 낮지만, 이 사실을 알고 있다는 것을 문서로 보여준다.
- 로그, 크래시 리포트, 스냅샷 테스트 이미지에 키가 들어가지 않게 한다.

## 체크리스트
- [ ] `git status`에 Secrets.xcconfig가 없는가
- [ ] 키 없이 빌드와 테스트가 통과하는가
- [ ] URL을 xcconfig에 넣지 않았는가
- [ ] 로그에 키가 마스킹되는가
