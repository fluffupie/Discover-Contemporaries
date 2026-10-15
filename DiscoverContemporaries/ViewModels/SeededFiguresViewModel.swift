import Combine
import Foundation
import OSLog

/// Manages loading and display state for a curated list of figures.
///
/// Used for any screen that shows a fixed, seeded list of Wikidata IDs, such
/// as the figures for an occupation or a continent.
@MainActor
final class SeededFiguresViewModel: ObservableObject {
    /// Whether a load is in progress with nothing cached to show.
    @Published private(set) var isLoading = false

    /// The figures, in the seeded order.
    @Published private(set) var figures: [HistoricalFigure] = []

    /// A message for the empty or failed state, or `nil`.
    @Published private(set) var errorMessage: String?

    /// Identifies what is currently loaded, so switching to a different list
    /// clears the old figures instead of showing them under the wrong title.
    private var currentKey: String?

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "DiscoverContemporaries",
        category: "SeededFigures"
    )

    /// Loads a curated list of figures.
    ///
    /// Cached figures appear immediately. Missing ones are fetched from
    /// Wikidata, saved to SwiftData, and the list is reloaded in seeded order.
    /// If the fetch fails, cached figures stay on screen.
    ///
    /// Call from `.task(id:)` with the same value as `key`, so a change of
    /// list cancels the previous load. Calling it again retries a failed load.
    ///
    /// - Parameters:
    ///   - key: A stable identifier for this list, for example an occupation ID.
    ///   - seededIDs: The Wikidata IDs to show, in display order.
    ///   - repository: The repository used to read and cache figures.
    func load(
        key: String,
        seededIDs: [String],
        repository: FigureCacheRepository
    ) async {
        if currentKey != key {
            figures = []
        }
        currentKey = key
        errorMessage = nil

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

        // 2. Only block the screen when nothing is available locally.
        isLoading = cached.isEmpty

        do {
            // 3. Fetch, cache, and reload in seeded order.
            let fetched = try await WikidataAPI.fetchFiguresInBatches(withIDs: missingIDs)
            try Task.checkCancellation()

            do {
                try repository.saveAll(fetched)
            } catch {
                logger.error("Failed to cache figures for \(key, privacy: .public): \(error.localizedDescription)")
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
            logger.error("Failed to load figures for \(key, privacy: .public): \(error.localizedDescription)")
            isLoading = false
            if cached.isEmpty {
                errorMessage = String(localized: "Couldn't load figures. Check your connection and try again.")
            }
        }
    }
}
