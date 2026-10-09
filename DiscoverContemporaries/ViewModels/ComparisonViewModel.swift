import Combine
import Foundation

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

    func resolveFigure(
        from result: WikidataSearchResult,
        repository: FigureCacheRepository,
        completion: @escaping (HistoricalFigure?) -> Void
    ) {
        // First try SwiftData.
        if let cachedFigure = try? repository.fetchFigure(
            withID: result.id
        ) {
            completion(cachedFigure)
            return
        }

        // Otherwise fetch full details.
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
