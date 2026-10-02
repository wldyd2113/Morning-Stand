import AppIntents

/// 기상 알람의 "출발 보기" 버튼. 앱을 열어 오늘의 출발 카운트다운(스탠드 화면)을 보여준다.
/// 협탁에 반접어 둔 상태면 자세 판정으로 바로 스탠드 화면이 뜬다.
struct OpenDepartureScreenIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "출발 화면 열기"
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
