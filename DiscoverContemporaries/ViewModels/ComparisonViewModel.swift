import Combine
import Foundation

/// Manages figure search, selection, and resolution for historical figure comparisons.
@MainActor
final class ComparisonViewModel: ObservableObject {

    // MARK: - Search State

    @Published var searchText = ""

    @Published private(set)
    var results: [WikidataSearchResult] = []

    @Published private(set)
    var isLoading = false

    @Published private(set)
    var errorMessage: String?

    private var searchTask: Task<Void, Never>?

    // MARK: - Search

    /// Debounces changes to the search text before performing a Wikidata search.
    func searchTextChanged() {
        searchTask?.cancel()

        let query = searchText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !query.isEmpty else {
            results = []
            errorMessage = nil
            isLoading = false
            return
        }

        searchTask = Task {
            try? await Task.sleep(
                for: .milliseconds(400)
            )

            guard !Task.isCancelled else {
                return
            }

            performSearch()
        }
    }

    /// Searches Wikidata for historical figures matching the current search text.
    func performSearch() {
        let query = searchText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !query.isEmpty else {
            results = []
            errorMessage = nil
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        WikidataAPI.fetchFigures(
            query: query
        ) { [weak self] results in
            guard let self else {
                return
            }

            let currentQuery = self.searchText
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            guard currentQuery == query else {
                return
            }

            self.results = results
            self.isLoading = false

            if results.isEmpty {
                self.errorMessage =
                    "No figures found."
            }
        }
    }

    // MARK: - Resolve Figure

    /// Resolves a search result into a complete historical figure for comparison.
    ///
    /// The method first checks the SwiftData cache and fetches missing details
    /// from Wikidata when necessary.
    ///
    /// - Parameters:
    ///   - result: The Wikidata search result to resolve.
    ///   - repository: The repository used to read and cache historical figures.
    ///   - completion: A closure containing the resolved historical figure, or `nil` if resolution fails.
    func resolveFigure(
        from result: WikidataSearchResult,
        repository: FigureCacheRepository,
        completion: @escaping (HistoricalFigure?) -> Void
    ) {
        if let cachedFigure = try? repository.fetchFigure(
            withID: result.id
        ) {
            completion(cachedFigure)
            return
        }

        WikidataAPI.fetchDetails(
            forID: result.id
        ) { details in
            guard let details else {
                completion(nil)
                return
            }

            let figure = HistoricalFigure(
                id: result.id,
                name: result.label,
                descriptionText: result.description,
                gender: nil,
                birthPlace: nil,
                birthDate: details.birthDate,
                deathDate: details.deathDate,
                occupations: [],
                movements: [],
                imageURL: details.portraitURL
                    ?? result.imageURL,
                imageName: nil
            )

            do {
                try repository.save(figure)
            } catch {
                print(
                    "Failed to cache comparison figure: \(error)"
                )
            }

            completion(figure)
        }
    }
}
