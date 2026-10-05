import Combine
import Foundation
import SwiftData

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var figure: HistoricalFigure

    @Published private(set) var cachedImageName: String?
    @Published private(set) var cachedImageURL: URL?
    @Published private(set) var cachedBirthPlace: String?
    @Published private(set) var cachedBirthDate: Date?
    @Published private(set) var cachedDeathDate: Date?
    
    @Published private(set) var isBookmarked = false
    @Published private(set) var bookmarkMessage: String?

    init(figure: HistoricalFigure) {
        self.figure = figure
    }
    
    func load(context: ModelContext) {
        let repository = FigureCacheRepository(context: context)
        load(repository: repository)
    }
    
    var summaryText: String {
        figure.descriptionText ?? "No description available yet."
    }

    var roleLabel: String {
        figure.primaryOccupation
    }

    var movementText: String {
        figure.movementsText
    }

    // MARK: - Resolved Values

    private var resolvedBirthDate: Date? {
        cachedBirthDate ?? figure.birthDate
    }

    private var resolvedDeathDate: Date? {
        cachedDeathDate ?? figure.deathDate
    }

    private var resolvedBirthPlace: String? {
        cachedBirthPlace ?? figure.birthPlace
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
        cachedBirthPlace = cached.birthPlace
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

            self.cachedBirthPlace = country
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
    
    func loadBookmarkState() async {
            do {
                isBookmarked = try await BookmarkService.shared.isSaved(figure.id)
            } catch {
                isBookmarked = false
            }
        }

        func toggleBookmark() async {
            do {
                if isBookmarked {
                    try await BookmarkService.shared.remove(figure.id)
                    isBookmarked = false
                    bookmarkMessage = "Removed from collection"
                } else {
                    try await BookmarkService.shared.save(figure)
                    isBookmarked = true
                    bookmarkMessage = "Figure saved!"
                }
            } catch {
                bookmarkMessage = "Something went wrong"
            }
        }

        func clearBookmarkMessage() {
            bookmarkMessage = nil
        }
}
