import Combine
import Foundation
import SwiftData

/// Manages profile display data, cache enrichment, and bookmark state for a historical figure.
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

    private var hasLoadedNetworkDetails = false

    init(figure: HistoricalFigure) {
        self.figure = figure
    }

    // MARK: - Display Values

    var summaryText: String {
        figure.descriptionText
            ?? "No description available yet."
    }

    var roleLabel: String {
        figure.primaryOccupation
    }

    var movementText: String {
        figure.movementsText
    }

    var imageName: String? {
        cachedImageName ?? figure.imageName
    }

    var imageURL: URL? {
        resolvedImageURL
    }

    var birthPlace: String {
        resolvedBirthPlace
            ?? "Unknown birth place"
    }

    var lifespanText: String {
        resolvedFigure.lifespan
    }

    var ageText: String {
        resolvedFigure.ageText
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

    /// Returns the most complete version of the current historical figure.
    ///
    /// Cached values are preferred when available so newly loaded profile
    /// details can be used throughout the profile and bookmark flows.
    var resolvedFigure: HistoricalFigure {
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

    // MARK: - Loading

    /// Loads profile data using a repository created from the supplied SwiftData context.
    ///
    /// - Parameter context: The SwiftData model context used to access cached figures.
    func load(context: ModelContext) {
        let repository = FigureCacheRepository(
            context: context
        )

        load(repository: repository)
    }

    /// Loads cached profile data and fetches missing details from Wikidata when needed.
    ///
    /// - Parameter repository: The repository used to read and persist historical figure data.
    func load(
        repository: FigureCacheRepository
    ) {
        loadFromCache(repository)

        guard needsNetworkDetails else {
            return
        }

        loadMissingDetails(
            repository: repository
        )
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
        guard !hasLoadedNetworkDetails else {
            return
        }

        hasLoadedNetworkDetails = true

        WikidataAPI.fetchDetails(
            forID: figure.id
        ) { [weak self] details in
            guard
                let self,
                let details
            else {
                return
            }

            if resolvedBirthDate == nil {
                cachedBirthDate = details.birthDate
            }

            if resolvedDeathDate == nil {
                cachedDeathDate = details.deathDate
            }

            if resolvedImageURL == nil {
                cachedImageURL = details.portraitURL
            }

            saveToCache(repository)
        }
    }

    private var needsNetworkDetails: Bool {
        !hasLoadedNetworkDetails
            && (
                resolvedBirthDate == nil
                    || resolvedImageURL == nil
            )
    }

    // MARK: - Cache Persistence

    private func saveToCache(
        _ repository: FigureCacheRepository
    ) {
        do {
            try repository.save(
                resolvedFigure
            )
        } catch {
            print(
                "Failed to cache figure \(figure.id): \(error)"
            )
        }
    }

    // MARK: - Bookmark

    /// Loads whether the current historical figure is saved as a bookmark.
    func loadBookmarkState() async {
        do {
            isBookmarked = try await BookmarkService
                .shared
                .isSaved(figure.id)
        } catch {
            isBookmarked = false
        }
    }

    /// Saves or removes the current historical figure based on its bookmark state.
    ///
    /// The resolved figure is saved so any cached profile details are included
    /// in the bookmark.
    func toggleBookmark() async {
        bookmarkMessage = nil

        do {
            if isBookmarked {
                try await BookmarkService
                    .shared
                    .remove(figure.id)

                isBookmarked = false
                bookmarkMessage = "Removed from collection"
            } else {
                try await BookmarkService
                    .shared
                    .save(resolvedFigure)

                isBookmarked = true
                bookmarkMessage = "Figure saved!"
            }
        } catch {
            bookmarkMessage = "Something went wrong"
        }
    }

    /// Clears the current bookmark status message.
    func clearBookmarkMessage() {
        bookmarkMessage = nil
    }
}
