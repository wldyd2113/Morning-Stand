import Foundation
import Observation

/// 미세먼지 측정소 선택.
@MainActor @Observable
final class AirQualityStationViewModel {
    private(set) var stations: SectionState<[String]> = .idle
    private(set) var selectedName: String

    @ObservationIgnored private let repository: any AirQualityStationRepository
    @ObservationIgnored private let settings: any UserSettingsRepository
    @ObservationIgnored private let dateProvider: any DateProvider

    init(repository: any AirQualityStationRepository, settings: any UserSettingsRepository, dateProvider: any DateProvider) {
        self.repository = repository
        self.settings = settings
        self.dateProvider = dateProvider
        self.selectedName = settings.airQualityStationName()
    }

    var errorMessage: String? {
        if case .failed(let error) = stations { return error.userMessage }
        return nil
    }

    func load() async {
        stations = stations.beginningLoad()
        do {
            let names = try await repository.stationNames()
            stations = .loaded(names, fetchedAt: dateProvider.now)
        } catch {
            stations = .failed(AppError(error))
        }
    }

    func select(_ name: String) {
        selectedName = name
        settings.setAirQualityStationName(name)
    }
}
