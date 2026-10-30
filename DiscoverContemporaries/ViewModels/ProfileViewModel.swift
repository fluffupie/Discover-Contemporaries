import Combine
import Foundation
import OSLog
import SwiftData

/// Manages profile display data, cache enrichment and bookmark state for a figure.
@MainActor
final class ProfileViewModel: ObservableObject {
    /// The figure shown, enriched in place from the cache and Wikidata.
    @Published var figure: HistoricalFigure

    @Published private(set) var isBookmarked = false
    @Published private(set) var bookmarkMessage: String?

    /// `true` while a save or remove is running. Use it to disable the button.
    @Published private(set) var isUpdatingBookmark = false

    private let bookmarkService: BookmarkServiceProtocol
    private var hasLoadedNetworkDetails = false
    private var isLoadingDetails = false
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "DiscoverContemporaries",
        category: "Profile"
    )

    /// Creates a view model.
    /// - Parameters:
    ///   - figure: The figure to show.
    ///   - bookmarkService: The service to use. Defaults to the shared one.
    init(
        figure: HistoricalFigure,
        bookmarkService: BookmarkServiceProtocol = BookmarkService.shared
    ) {
        self.figure = figure
        self.bookmarkService = bookmarkService
    }

    // MARK: - Display Values

    var summaryText: String {
        figure.descriptionText ?? String(localized: "No description available yet.")
    }

    var roleLabel: String { figure.primaryOccupation }
    var movementText: String { figure.movementsText }
    var imageName: String? { figure.imageName }
    var imageURL: URL? { figure.imageURL }

    var birthPlace: String {
        figure.birthPlace ?? String(localized: "Unknown birth place")
    }

    var lifespanText: String { figure.lifespan }
    var ageText: String { figure.ageText }

    /// The most complete version of the figure, used for bookmarking.
    var resolvedFigure: HistoricalFigure { figure }

    // MARK: - Loading

    /// Loads profile data using a repository made from the given context.
    func load(context: ModelContext) async {
        await load(repository: FigureCacheRepository(context: context))
    }

    /// Fills the profile from the cache, then fetches whatever is still
    /// missing from Wikidata and caches the result.
    ///
    /// Call from `.task` so leaving the screen cancels it.
    func load(repository: FigureCacheRepository) async {
        loadFromCache(repository)

        guard needsNetworkDetails, !isLoadingDetails else { return }
        await loadMissingDetails(repository: repository)
    }

    /// Merges the cached record into `figure`.
    ///
    /// Reading through `fetchFigure(withID:)` also records the figure as
    /// recently viewed, which is intended for a profile screen.
    private func loadFromCache(_ repository: FigureCacheRepository) {
        do {
            if let cached = try repository.fetchFigure(withID: figure.id) {
                figure = figure.filling(gapsFrom: cached)
            }
        } catch {
            logger.error("Cache read failed for \(self.figure.id): \(error.localizedDescription)")
        }
    }

    // MARK: - Network Loading

    private var needsNetworkDetails: Bool {
        !hasLoadedNetworkDetails
            && (figure.birthDate == nil
                || figure.imageURL == nil
                || figure.birthPlace == nil)
    }

    private func loadMissingDetails(repository: FigureCacheRepository) async {
        let figureID = figure.id
        isLoadingDetails = true
        defer { isLoadingDetails = false }

        do {
            guard let details = try await WikidataAPI.fetchDetails(forID: figureID) else {
                hasLoadedNetworkDetails = true
                return
            }

            // A failed place lookup shouldn't discard the dates and portrait.
            var placeName: String?
            var countryName: String?
            if let birthPlaceID = details.birthPlaceID {

                // Option B: Use your new SPARQL helper to get the country
                countryName = try? await WikidataAPI.fetchBirthCountry(forID: figureID)
            }

            
            if figure.birthPlace == nil, let placeID = details.birthPlaceID {
                placeName = try? await WikidataAPI.fetchEntityLabel(forID: placeID)
            }

            try Task.checkCancellation()
            guard figure.id == figureID else { return }  // figure changed meanwhile

            let fetched = HistoricalFigure(
                id: figureID,
                name: figure.name,
                descriptionText: nil,
                gender: nil,
                birthPlace: countryName,
                birthDate: details.birthDate,
                deathDate: details.deathDate,
                occupations: [],
                movements: [],
                imageURL: details.portraitURL,
                imageName: nil
            )

            figure = figure.filling(gapsFrom: fetched)
            hasLoadedNetworkDetails = true
            saveToCache(repository)
        } catch is CancellationError {
            // The view went away. A later load can try again.
        } catch let error as URLError where error.code == .cancelled {
            // Same, surfaced by URLSession.
        } catch {
            logger.error("Details failed for \(figureID): \(error.localizedDescription)")
        }
    }

    // MARK: - Cache Persistence

    private func saveToCache(_ repository: FigureCacheRepository) {
        do {
            try repository.save(figure)
        } catch {
            logger.error("Failed to cache \(self.figure.id): \(error.localizedDescription)")
        }
    }

    // MARK: - Bookmark

    /// Loads whether the figure is saved. On failure the heart stays unsaved.
    func loadBookmarkState() async {
        do {
            isBookmarked = try await bookmarkService.isSaved(figure.id)
        } catch is CancellationError {
            // The view went away.
        } catch {
            logger.error("Bookmark state failed: \(error.localizedDescription)")
        }
    }

    /// Saves or removes the figure. Calls made while one is running are ignored.
    ///
    /// The saved bookmark includes everything merged into ``figure``.
    func toggleBookmark() async {
        guard !isUpdatingBookmark else { return }
        isUpdatingBookmark = true
        bookmarkMessage = nil
        defer { isUpdatingBookmark = false }

        do {
            if isBookmarked {
                try await bookmarkService.remove(figure.id)
                isBookmarked = false
                bookmarkMessage = String(localized: "Removed from collection")
            } else {
                try await bookmarkService.save(figure)
                isBookmarked = true
                bookmarkMessage = String(localized: "Figure saved!")
            }
        } catch is CancellationError {
            // The view went away.
        } catch {
            logger.error("Bookmark toggle failed: \(error.localizedDescription)")
            bookmarkMessage = String(localized: "Something went wrong")
        }
    }

    /// Clears the bookmark status message.
    func clearBookmarkMessage() {
        bookmarkMessage = nil
    }
}

// MARK: - Merging

private extension HistoricalFigure {
    /// A copy that keeps this figure's values and fills missing ones from `other`.
    func filling(gapsFrom other: HistoricalFigure) -> HistoricalFigure {
        HistoricalFigure(
            id: id,
            name: name,
            descriptionText: descriptionText ?? other.descriptionText,
            gender: gender ?? other.gender,
            birthPlace: birthPlace ?? other.birthPlace,
            birthDate: birthDate ?? other.birthDate,
            deathDate: deathDate ?? other.deathDate,
            occupations: occupations.isEmpty ? other.occupations : occupations,
            movements: movements.isEmpty ? other.movements : movements,
            imageURL: imageURL ?? other.imageURL,
            imageName: imageName ?? other.imageName
        )
    }
}
