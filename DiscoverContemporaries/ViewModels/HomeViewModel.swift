import Combine
import Foundation

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

    var hasSearchQuery: Bool {
        !trimmedSearchText.isEmpty
    }

    // MARK: - Homepage Figures

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
    func clearSearch() {
        searchText = ""
        searchResults = []
        errorMessage = nil
        isLoading = false
    }

    // MARK: - Helpers

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
