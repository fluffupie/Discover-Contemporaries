import Combine
import Foundation
import OSLog

/// Manages homepage figure selection, recent history and figure search.
@MainActor
final class HomeViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var searchResults: [WikidataSearchResult] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    /// The figures featured on the home screen, in display order.
    private static let defaultFigureIDs = [
        "Q7259", // Ada Lovelace
        "Q5582",  // Vincent van Gogh (Q5582)
        "Q2831", // Michael Jackson
        "Q9682"  // Elizabeth II
    ]

    /// The maximum number of recently viewed figures shown.
    private static let recentLimit = 5

    private var searchTask: Task<Void, Never>?
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "DiscoverContemporaries",
        category: "Home"
    )

    /// Whether the search text contains a non-empty query.
    var hasSearchQuery: Bool {
        !trimmedSearchText.isEmpty
    }

    // MARK: - Homepage Figures

    /// Returns the default homepage figures found in the cache, in the
    /// predefined order. Figures not yet cached are skipped.
    ///
    /// - Parameter cachedFigures: The figures currently in the local cache.
    func defaultFigures(from cachedFigures: [CachedHistoricalFigure]) -> [HistoricalFigure] {
        let byID = Dictionary(
            cachedFigures.map { ($0.wikidataID, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        return Self.defaultFigureIDs.compactMap { byID[$0]?.historicalFigure }
    }

    /// Returns the most recently viewed figures, newest first.
    ///
    /// Default homepage figures are excluded.
    ///
    /// - Parameter cachedFigures: The figures currently in the local cache.
    func recentlyViewedFigures(from cachedFigures: [CachedHistoricalFigure]) -> [HistoricalFigure] {
        cachedFigures
            .compactMap { cached -> (CachedHistoricalFigure, Date)? in
                guard
                    !Self.defaultFigureIDs.contains(cached.wikidataID),
                    let viewedAt = cached.lastViewedAt
                else { return nil }
                return (cached, viewedAt)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(Self.recentLimit)
            .map { $0.0.historicalFigure }
    }

    // MARK: - Search

    /// Searches Wikidata for the current search text.
    ///
    /// Any search still running is cancelled, so only the latest one can
    /// update the results.
    func searchFigures() {
        searchTask?.cancel()

        let query = trimmedSearchText
        guard !query.isEmpty else {
            return
        }

        isLoading = true
        errorMessage = nil

        searchTask = Task { [weak self] in
            do {
                let results = try await WikidataAPI.fetchFigures(query: query)
                try Task.checkCancellation()
                self?.finishSearch(with: results)
            } catch is CancellationError {
                // Superseded by a newer search. The newer task owns the state.
            } catch let error as URLError where error.code == .cancelled {
                // Same, surfaced by URLSession.
            } catch {
                self?.failSearch(error)
            }
        }
    }

    /// Cancels any running search and clears the text, results and messages.
//    func clearSearch() {
//        searchTask?.cancel()
//        searchText = ""
//        searchResults = []
//        errorMessage = nil
//        isLoading = false
//    }

    private func finishSearch(with results: [WikidataSearchResult]) {
        searchResults = results
        isLoading = false
        errorMessage = results.isEmpty ? String(localized: "No figures found.") : nil
    }

    private func failSearch(_ error: Error) {
        logger.error("Search failed: \(error.localizedDescription)")
        searchResults = []
        isLoading = false
        errorMessage = String(localized: "Search failed. Check your connection and try again.")
    }

    // MARK: - Helpers

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
