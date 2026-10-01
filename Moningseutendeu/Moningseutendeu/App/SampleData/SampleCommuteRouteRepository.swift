import Foundation
import Synchronization

/// 즐겨찾기 경로·루틴 샘플. 값은 디자인 시안과 같다. 수정은 메모리에만 반영된다.
nonisolated final class SampleCommuteRouteRepository: CommuteRouteRepository {
    private struct State {
        var routes: [CommuteRoute]
        var routines: [RoutineSetting]
    }

    // Mutex로 보호하므로 여러 Task에서 안전하게 읽고 쓴다
    private let state = Mutex(State(routes: SampleCommuteRouteRepository.routes, routines: SampleCommuteRouteRepository.routines))

    static let routes: [CommuteRoute] = [
        CommuteRoute(
            id: "home-office", name: "집 → 회사", origin: "불광동", destination: "광화문",
            departure: TimeOfDay(hour: 8, minute: 10), weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            options: [
                RouteOption(id: "1711", title: "1711번", note: "환승 없음", segments: [
                    RouteSegment(kind: .walk, minutes: 5), RouteSegment(kind: .wait, minutes: 7),
                    RouteSegment(kind: .bus, minutes: 22, label: "1711번"), RouteSegment(kind: .walk, minutes: 7),
                ]),
                RouteOption(id: "line3-line5", title: "3호선 → 5호선", note: "환승 1회", segments: [
                    RouteSegment(kind: .walk, minutes: 8), RouteSegment(kind: .wait, minutes: 3),
                    RouteSegment(kind: .subway, minutes: 14, label: "3호선"), RouteSegment(kind: .transfer, minutes: 4),
                    RouteSegment(kind: .subway, minutes: 9, label: "5호선"), RouteSegment(kind: .walk, minutes: 8),
                ]),
                RouteOption(id: "7212", title: "7212번", note: "덜 붐빔", segments: [
                    RouteSegment(kind: .walk, minutes: 5), RouteSegment(kind: .wait, minutes: 12),
                    RouteSegment(kind: .bus, minutes: 29, label: "7212번"), RouteSegment(kind: .walk, minutes: 6),
                ]),
            ]
        ),
        CommuteRoute(
            id: "home-academy", name: "집 → 학원", origin: "불광동", destination: "신촌",
            departure: TimeOfDay(hour: 18, minute: 40), weekdays: [.tuesday, .thursday],
            options: [
                RouteOption(id: "720", title: "720번", note: "환승 없음", segments: [
                    RouteSegment(kind: .walk, minutes: 5), RouteSegment(kind: .wait, minutes: 4),
                    RouteSegment(kind: .bus, minutes: 21, label: "720번"), RouteSegment(kind: .walk, minutes: 8),
                ]),
                RouteOption(id: "line3-line2", title: "3호선 → 2호선", note: "환승 1회", segments: [
                    RouteSegment(kind: .walk, minutes: 8), RouteSegment(kind: .wait, minutes: 3),
                    RouteSegment(kind: .subway, minutes: 12, label: "3호선"), RouteSegment(kind: .transfer, minutes: 5),
                    RouteSegment(kind: .subway, minutes: 10, label: "2호선"), RouteSegment(kind: .walk, minutes: 5),
                ]),
            ]
        ),
        CommuteRoute(
            id: "home-parents", name: "집 → 본가", origin: "불광동", destination: "일산",
            departure: TimeOfDay(hour: 10, minute: 30), weekdays: [.saturday],
            options: [
                RouteOption(id: "line3", title: "3호선", note: "환승 없음", segments: [
                    RouteSegment(kind: .walk, minutes: 8), RouteSegment(kind: .wait, minutes: 4),
                    RouteSegment(kind: .subway, minutes: 38, label: "3호선"), RouteSegment(kind: .walk, minutes: 8),
                ]),
                RouteOption(id: "9701", title: "9701번", note: "좌석버스", segments: [
                    RouteSegment(kind: .walk, minutes: 5), RouteSegment(kind: .wait, minutes: 9),
                    RouteSegment(kind: .bus, minutes: 40, label: "9701번"), RouteSegment(kind: .walk, minutes: 8),
                ]),
            ]
        ),
    ]

    static let routines: [RoutineSetting] = {
        let office1711 = "집 → 회사 · 1711번"
        let weekday = TimeOfDay(hour: 8, minute: 10)
        return [
            RoutineSetting(weekday: .monday, isEnabled: true, departure: weekday, routeDescription: office1711, alertLeadMinutes: 5),
            RoutineSetting(weekday: .tuesday, isEnabled: true, departure: weekday, routeDescription: office1711, alertLeadMinutes: 5),
            RoutineSetting(weekday: .wednesday, isEnabled: true, departure: weekday, routeDescription: office1711, alertLeadMinutes: 5),
            RoutineSetting(weekday: .thursday, isEnabled: true, departure: weekday, routeDescription: office1711, alertLeadMinutes: 5),
            RoutineSetting(weekday: .friday, isEnabled: true, departure: TimeOfDay(hour: 8, minute: 30), routeDescription: "집 → 회사 · 3호선", alertLeadMinutes: 10),
            RoutineSetting(weekday: .saturday, isEnabled: true, departure: TimeOfDay(hour: 10, minute: 30), routeDescription: "집 → 본가 · 3호선", alertLeadMinutes: 10),
            RoutineSetting(weekday: .sunday, isEnabled: false),
        ]
    }()

    func fetchRoutes() async throws -> [CommuteRoute] { state.withLock { $0.routes } }
    func fetchRoutines() async throws -> [RoutineSetting] { state.withLock { $0.routines } }

    func saveRoute(_ route: CommuteRoute) throws {
        state.withLock { state in
            if let index = state.routes.firstIndex(where: { $0.id == route.id }) {
                state.routes[index] = route
            } else {
                state.routes.append(route)
            }
        }
    }

    func deleteRoute(id: String) throws {
        state.withLock { $0.routes.removeAll { $0.id == id } }
    }

    func saveRoutine(_ routine: RoutineSetting) throws {
        state.withLock { state in
            state.routines.removeAll { $0.weekday == routine.weekday }
            state.routines.append(routine)
        }
    }
}
