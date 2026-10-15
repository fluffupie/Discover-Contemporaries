import Combine
import Foundation
import OSLog

/// Manages figure search, selection and resolution for comparisons.
@MainActor
final class ComparisonViewModel: ObservableObject {
    // MARK: - Search State

    /// The text in the search field.
    @Published var searchText = ""

    /// The people matching the current search.
    @Published private(set) var results: [WikidataSearchResult] = []

    /// Whether a search is in progress.
    @Published private(set) var isLoading = false

    /// A message for the empty or failed state, or `nil`.
    @Published private(set) var errorMessage: String?

    private var searchTask: Task<Void, Never>?
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "DiscoverContemporaries",
        category: "Comparison"
    )

    // MARK: - Search

    /// Debounces changes to the search text, then searches Wikidata.
    ///
    /// Call this whenever `searchText` changes. Any search still running is
    /// cancelled.
    func searchTextChanged() {
        startSearch(debounce: .milliseconds(400))
    }

    /// Searches immediately for the current text, skipping the debounce.
    func performSearch() {
        startSearch(debounce: nil)
    }

    private func startSearch(debounce: Duration?) {
        searchTask?.cancel()

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            results = []
            errorMessage = nil
            isLoading = false
            return
        }

        searchTask = Task { [weak self] in
            do {
                if let debounce {
                    try await Task.sleep(for: debounce)
                }
                try await self?.runSearch(query: query)
            } catch is CancellationError {
                // Superseded by newer input. The newer task owns the state.
            } catch let error as URLError where error.code == .cancelled {
                // Same, surfaced by URLSession.
            } catch {
                self?.handleSearchFailure(error)
            }
        }
    }

    private func runSearch(query: String) async throws {
        isLoading = true
        errorMessage = nil

        let found = try await WikidataAPI.fetchFigures(query: query)
        try Task.checkCancellation()

        results = found
        isLoading = false
        if found.isEmpty {
            errorMessage = String(localized: "No figures found.")
        }
    }

    private func handleSearchFailure(_ error: Error) {
        logger.error("Search failed: \(error.localizedDescription)")
        results = []
        isLoading = false
        errorMessage = String(localized: "Search failed. Check your connection and try again.")
    }

    // MARK: - Resolve Figure

    /// Resolves a search result into a figure for comparison.
    ///
    /// Checks the SwiftData cache first, then fetches the missing details from
    /// Wikidata and caches the new figure.
    ///
    /// - Parameters:
    ///   - result: The search result to resolve.
    ///   - repository: The repository used to read and cache figures.
    /// - Returns: The figure, or `nil` if Wikidata has no such entity.
    /// - Throws: ``WikidataError`` or the underlying `URLError` if the request
    ///   fails, including cancellation.
    func resolveFigure(
        from result: WikidataSearchResult,
        repository: FigureCacheRepository
    ) async throws -> HistoricalFigure? {
        if let cached = try? repository.fetchFigure(withID: result.id) {
            return cached
        }

        guard let details = try await WikidataAPI.fetchDetails(forID: result.id) else {
            return nil
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
            imageURL: details.portraitURL ?? result.imageURL,
            imageName: nil
        )

        do {
            try repository.save(figure)
        } catch {
            logger.error("Failed to cache comparison figure: \(error.localizedDescription)")
        }

        return figure
    }
}
