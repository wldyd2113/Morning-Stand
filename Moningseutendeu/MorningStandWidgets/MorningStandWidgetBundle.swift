import SwiftUI
import WidgetKit

/// 모닝스탠드 위젯 익스텐션. 네트워크를 쓰지 않고 앱이 App Group에 써 둔 스냅샷만 읽는다.
@main
struct MorningStandWidgetBundle: WidgetBundle {
    var body: some Widget {
        DepartureWidget()
        DepartureLiveActivity()
    }
}
