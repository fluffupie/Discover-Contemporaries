import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {

    @Published var searchText = ""
    @Published var searchResults: [WikidataSearchResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func searchFigures() {
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else {
            clearSearch()
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

            self.searchResults = results
            self.isLoading = false

            if results.isEmpty {
                self.errorMessage = "No figures found."
            }
        }
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
        errorMessage = nil
        isLoading = false
    }
}
