import Combine
import Foundation
import OSLog

/// Manages loading and display state for a continent's curated figures.
@MainActor
final class ContinentTopFiguresViewModel: ObservableObject {
    /// Whether a load is in progress with nothing cached to show.
    @Published private(set) var isLoading = false

    /// The figures, in the seeded order.
    @Published private(set) var figures: [HistoricalFigure] = []

    /// A message for the empty or failed state, or `nil`.
    @Published private(set) var errorMessage: String?

    private var currentContinentID: String?
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "DiscoverContemporaries",
        category: "Continents"
    )

    /// Loads the curated figures for a continent.
    ///
    /// Cached figures appear immediately. Missing ones are fetched from
    /// Wikidata, saved to SwiftData, and the list is reloaded in seeded order.
    /// If the fetch fails, cached figures stay on screen.
    ///
    /// Call from `.task(id: continent.id)` so a change of continent cancels
    /// the previous load.
    ///
    /// - Parameters:
    ///   - continent: The continent to load.
    ///   - repository: The repository used to read and cache figures.
    func load(
        for continent: Continent,
        repository: FigureCacheRepository
    ) async {
        let continentID = continent.id
        if currentContinentID != continentID {
            figures = []
        }
        currentContinentID = continentID
        errorMessage = nil

        let seededIDs = ContinentFigureIDs.ids(for: continentID)
        guard !seededIDs.isEmpty else {
            figures = []
            isLoading = false
            errorMessage = String(localized: "No figures found.")
            return
        }

        // 1. Show whatever is already cached.
        let cached = (try? repository.fetchFigures(withIDs: seededIDs)) ?? []
        figures = cached

        let cachedIDs = Set(cached.map(\.id))
        let missingIDs = seededIDs.filter { !cachedIDs.contains($0) }

        guard !missingIDs.isEmpty else {
            isLoading = false
            return
        }

        // 2. Only show a full loading state when nothing is available locally.
        isLoading = cached.isEmpty

        do {
            // 3. Fetch, cache, and reload in seeded order.
            let fetched = try await WikidataAPI.fetchFiguresInBatches(withIDs: missingIDs)
            try Task.checkCancellation()

            do {
                try repository.saveAll(fetched)
            } catch {
                logger.error("Failed to cache continent figures: \(error.localizedDescription)")
            }

            figures = (try? repository.fetchFigures(withIDs: seededIDs)) ?? cached + fetched
            isLoading = false
            if figures.isEmpty {
                errorMessage = String(localized: "No figures found.")
            }
        } catch is CancellationError {
            // Superseded or the view went away. Leave the state to the newer load.
        } catch let error as URLError where error.code == .cancelled {
            // Same, surfaced by URLSession.
        } catch {
            logger.error("Failed to load continent figures: \(error.localizedDescription)")
            isLoading = false
            if cached.isEmpty {
                errorMessage = String(localized: "Couldn't load figures. Check your connection and try again.")
            }
        }
    }
}
