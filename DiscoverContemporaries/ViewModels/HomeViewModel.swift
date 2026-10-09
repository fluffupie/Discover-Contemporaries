import Combine
import Foundation

/// Manages homepage figure selection, recent history, and figure search.
@MainActor
final class HomeViewModel: ObservableObject {

    @Published var searchText = ""
    @Published private(set) var searchResults: [WikidataSearchResult] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let defaultFigureIDs = [
        "Q7259", // Ada Lovelace
        "Q762",  // Leonardo da Vinci
        "Q2831", // Michael Jackson
        "Q9682"  // Elizabeth II
    ]

    /// Indicates whether the current search text contains a non-empty query.
    var hasSearchQuery: Bool {
        !trimmedSearchText.isEmpty
    }

    // MARK: - Homepage Figures

    /// Returns the default homepage figures from the local SwiftData cache.
    ///
    /// Figures are returned in the predefined homepage order.
    ///
    /// - Parameter cachedFigures: The historical figures currently stored in the local cache.
    /// - Returns: The cached default historical figures.
    func defaultFigures(
        from cachedFigures: [CachedHistoricalFigure]
    ) -> [HistoricalFigure] {
        let figuresByID = Dictionary(
            uniqueKeysWithValues: cachedFigures.map {
                ($0.wikidataID, $0)
            }
        )

        return defaultFigureIDs.compactMap {
            figuresByID[$0]?.historicalFigure
        }
    }

    /// Returns up to five recently viewed historical figures.
    ///
    /// Default homepage figures are excluded, and the remaining figures are
    /// ordered from most recently viewed to least recently viewed.
    ///
    /// - Parameter cachedFigures: The historical figures currently stored in the local cache.
    /// - Returns: Up to five recently viewed historical figures.
    func recentlyViewedFigures(
        from cachedFigures: [CachedHistoricalFigure]
    ) -> [HistoricalFigure] {
        cachedFigures
            .filter {
                !defaultFigureIDs.contains($0.wikidataID)
                    && $0.lastViewedAt != nil
            }
            .sorted {
                ($0.lastViewedAt ?? .distantPast)
                    > ($1.lastViewedAt ?? .distantPast)
            }
            .prefix(5)
            .map(\.historicalFigure)
    }

    // MARK: - Search

    /// Searches Wikidata for historical figures matching the current search text.
    ///
    /// Results from outdated requests are ignored if the search text changes
    /// before the request completes.
    func searchFigures() {
        let query = trimmedSearchText

        guard !query.isEmpty else {
            clearSearch()
            return
        }

        isLoading = true
        errorMessage = nil

        WikidataAPI.fetchFigures(query: query) { [weak self] results in
            guard let self else {
                return
            }

            guard query == trimmedSearchText else {
                return
            }

            searchResults = results
            isLoading = false
            errorMessage = results.isEmpty
                ? "No figures found."
                : nil
        }
    }

    /// Clears the current search text, results, loading state, and error message.
    func clearSearch() {
        searchText = ""
        searchResults = []
        errorMessage = nil
        isLoading = false
    }

    // MARK: - Helpers

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }
}
