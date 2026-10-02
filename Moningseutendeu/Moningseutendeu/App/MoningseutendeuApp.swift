import SwiftUI

@main
struct MoningseutendeuApp: App {
    private let dependencies: AppDependencies

    init() {
        let dependencies = AppDependencies.live()
        self.dependencies = dependencies
        // 지역 감시(CLMonitor)로 앱이 백그라운드에서 깨어나면 화면이 만들어지지 않을 수 있어서
        // View의 `.task`가 아니라 앱 시작 시점에 구독한다. 앱이 살아 있는 동안 계속 돈다.
        Task { await dependencies.commuteAutomation.run() }
    }

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
        }
    }
}
