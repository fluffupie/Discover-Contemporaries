import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var figure: HistoricalFigure

    @Published private(set) var cachedImageName: String?
    @Published private(set) var cachedImageURL: URL?
    @Published private(set) var cachedCountry: String?
    @Published private(set) var cachedBirthDate: Date?
    @Published private(set) var cachedDeathDate: Date?

    init(figure: HistoricalFigure) {
        self.figure = figure
    }

    // MARK: - Resolved Values

    private var resolvedBirthDate: Date? {
        cachedBirthDate ?? figure.birthDate
    }

    private var resolvedDeathDate: Date? {
        cachedDeathDate ?? figure.deathDate
    }

    private var resolvedBirthPlace: String? {
        cachedCountry ?? figure.birthPlace
    }

    private var resolvedImageURL: URL? {
        cachedImageURL ?? figure.imageURL
    }

    // MARK: - UI Values

    var imageName: String? {
        cachedImageName ?? figure.imageName
    }

    var imageURL: URL? {
        resolvedImageURL
    }

    var birthPlace: String {
        resolvedBirthPlace ?? "Unknown birth place"
    }

    var lifespanText: String {
        resolvedFigure.lifespan
    }

    var ageText: String {
        resolvedFigure.ageText
    }

    // MARK: - Loading

    func load(repository: FigureCacheRepository) {
        loadFromCache(repository)

        guard needsNetworkDetails else {
            return
        }

        loadMissingDetails(repository: repository)
    }

    private func loadFromCache(
        _ repository: FigureCacheRepository
    ) {
        guard
            let cached = try? repository.fetchFigure(
                withID: figure.id
            )
        else {
            return
        }

        cachedImageName = cached.imageName
        cachedImageURL = cached.imageURL
        cachedCountry = cached.birthPlace
        cachedBirthDate = cached.birthDate
        cachedDeathDate = cached.deathDate
    }

    // MARK: - Network Loading

    private func loadMissingDetails(
        repository: FigureCacheRepository
    ) {
        WikidataAPI.fetchDetails(
            forID: figure.id
        ) { [weak self] details in
            guard
                let self,
                let details
            else {
                return
            }

            if self.resolvedBirthDate == nil {
                self.cachedBirthDate = details.birthDate
            }

            if self.resolvedDeathDate == nil {
                self.cachedDeathDate = details.deathDate
            }

            if self.resolvedImageURL == nil {
                self.cachedImageURL = details.portraitURL
            }

            self.loadCountryIfNeeded(
                countryID: details.countryID,
                repository: repository
            )

            self.saveToCache(repository)
        }
    }

    private func loadCountryIfNeeded(
        countryID: String?,
        repository: FigureCacheRepository
    ) {
        guard
            resolvedBirthPlace == nil,
            let countryID
        else {
            return
        }

        WikidataAPI.fetchEntityLabel(
            forID: countryID
        ) { [weak self] country in
            guard
                let self,
                let country
            else {
                return
            }

            self.cachedCountry = country
            self.saveToCache(repository)
        }
    }

    // MARK: - Network State

    private var needsNetworkDetails: Bool {
        resolvedBirthDate == nil
            || resolvedDeathDate == nil
            || resolvedImageURL == nil
            || resolvedBirthPlace == nil
    }

    // MARK: - Resolved Figure

    private var resolvedFigure: HistoricalFigure {
        HistoricalFigure(
            id: figure.id,
            name: figure.name,
            descriptionText: figure.descriptionText,
            gender: figure.gender,
            birthPlace: resolvedBirthPlace,
            birthDate: resolvedBirthDate,
            deathDate: resolvedDeathDate,
            occupations: figure.occupations,
            movements: figure.movements,
            imageURL: resolvedImageURL,
            imageName: imageName
        )
    }

    // MARK: - Cache Persistence

    private func saveToCache(
        _ repository: FigureCacheRepository
    ) {
        do {
            try repository.save(resolvedFigure)
        } catch {
            print(
                "Failed to cache figure \(figure.id): \(error)"
            )
        }
    }
}
