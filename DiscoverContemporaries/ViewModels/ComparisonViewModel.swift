import Combine
import Foundation

@MainActor
final class ComparisonViewModel: ObservableObject {
    @Published var searchText = ""

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var results: [WikidataSearchResult] = []

    private var searchTask: Task<Void, Never>?

    // MARK: - Search

    func searchTextChanged() {
        searchTask?.cancel()

        guard !trimmedSearchText.isEmpty else {
            clearResults()
            return
        }

        searchTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))

            guard !Task.isCancelled else {
                return
            }

            performSearch()
        }
    }

    func performSearch() {
        let query = trimmedSearchText

        guard !query.isEmpty else {
            clearResults()
            return
        }

        isLoading = true
        errorMessage = nil

        WikidataAPI.fetchFigures(query: query) { [weak self] newResults in
            guard let self else {
                return
            }

            results = newResults
            isLoading = false

            if newResults.isEmpty {
                errorMessage = "No results found."
            }
        }
    }

    func clearSearch() {
        searchText = ""
        clearResults()
    }

    // MARK: - Figure Selection

    func resolveFigure(
        from result: WikidataSearchResult,
        repository: FigureCacheRepository
    ) async -> HistoricalFigure? {

        if let cachedFigure = try? repository.fetchFigure(
            withID: result.id
        ) {
            return cachedFigure
        }

        guard let figure = await fetchFigureDetails(
            from: result
        ) else {
            errorMessage = "Unable to load figure details."
            return nil
        }

        do {
            try repository.save(figure)
        } catch {
            print(
                "Failed to cache comparison figure \(figure.id): \(error)"
            )
        }

        return figure
    }

    // MARK: - Helpers

    private func fetchFigureDetails(
        from result: WikidataSearchResult
    ) async -> HistoricalFigure? {
        await withCheckedContinuation { continuation in
            WikidataAPI.fetchDetails(
                forID: result.id
            ) { details in

                guard let details else {
                    continuation.resume(
                        returning: nil
                    )
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
                    imageURL: details.portraitURL,
                    imageName: nil
                )

                continuation.resume(
                    returning: figure
                )
            }
        }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private func clearResults() {
        results = []
        errorMessage = nil
        isLoading = false
    }
}
