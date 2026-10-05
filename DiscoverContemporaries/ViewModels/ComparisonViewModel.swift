import Combine
import Foundation

@MainActor
final class ComparisonViewModel: ObservableObject {
    @Published var searchText = ""

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var results: [WikidataSearchResult] = []

    private var searchTask: Task<Void, Never>?

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
            guard let self else { return }

            results = newResults
            isLoading = false

            if newResults.isEmpty {
                errorMessage = "No results found."
            }
        }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func clearResults() {
        results = []
        errorMessage = nil
        isLoading = false
    }
}
